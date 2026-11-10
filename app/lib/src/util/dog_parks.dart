import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import 'format.dart';

/// 「近くの公園を探す」機能のデータ層。
/// OpenStreetMap の Overpass API で現在地周辺の**公園**を取得する。
/// - ドッグラン（leisure=dog_park）は一覧に含めない
/// - 犬同伴が明確に禁止（dog=no）の公園は除外。
///   犬 OK（dog=yes / dog=leashed）の場合はその旨を表示する
/// - waysのみ取得（relationsを含むbboxクエリは重すぎて各サーバーが
///   502/504を返すため。大きな公園でrelationのみのものは表示されない）
/// - 取得には30〜60秒ほどかかることがあるため、同一場所なら
///   端末内キャッシュ（約100mグリッド・30分）を優先して返す
/// 取得結果は現在地からの距離の昇順に並べる。

/// Overpass サーバー（本家は混雑しやすいので、順にフォールバックする）
const List<String> overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

const int maxParks = 30;
const double searchRadiusKm = 5.0;
/// 本家サーバーの混雑時は応答まで30〜60秒かかる
const Duration parkFetchTimeout = Duration(seconds: 60);
const Duration parkCacheTtl = Duration(minutes: 30);

/// Overpass は既定の User-Agent を持つ要求を拒否（406）するため、
/// 必ずアプリ名入り UA を送る
Map<String, String> get parkHttpHeaders => {
      'User-Agent':
          'Inutomo/1.0 (Android; park search; +https://github.com/daichiyabunaka-rgb/Inutomo-app-prototype)',
      'Accept': 'application/json',
    };

/// Overpass API に投げるクエリ（bbox は南,西,北,東の順）
String buildOverpassQuery(double lat, double lng, {double radiusKm = searchRadiusKm}) {
  final dLat = radiusKm / 111.32;
  final cosLat = (lat * 3.1415926535897932 / 180.0).abs().clamp(0.01, 1.0);
  final dLng = radiusKm / (111.32 * cosLat);
  final south = lat - dLat;
  final west = lng - dLng;
  final north = lat + dLat;
  final east = lng + dLng;
  final bbox = '$south,$west,$north,$east';
  return '[out:json][timeout:25];'
      '('
      'node["leisure"="park"]["dog"!="no"]($bbox);'
      'way["leisure"="park"]["dog"!="no"]($bbox);'
      ');'
      'out center tags;';
}

/// 現在地周辺の公園を取得する（距離昇順）。
/// 同一地点（約100mグリッド）で30分以内の取得結果があればキャッシュを返す。
/// ドッグランは一覧に含めない。Overpass のサーバーに順にフォールバックし、
/// すべて失敗したら例外を投げる。
Future<List<DogPark>> fetchDogParksNear(
  double lat,
  double lng, {
  http.Client? client,
  bool forceRefresh = false,
}) async {
  final key = _cacheKey(lat, lng);
  final now = DateTime.now();
  if (!forceRefresh) {
    if (_memParks != null &&
        _memKey == key &&
        now.isBefore(_memAt.add(parkCacheTtl))) {
      return _memParks!;
    }
    final disk = await _loadDiskCache(key, now);
    if (disk != null) {
      _memKey = key;
      _memAt = now;
      _memParks = disk;
      return disk;
    }
  }
  final parks = await _fetchFromOverpass(lat, lng, client ?? http.Client(),
      clientProvided: client != null);
  _memKey = key;
  _memAt = DateTime.now();
  _memParks = parks;
  await _saveDiskCache(key, parks, _memAt);
  return parks;
}

Future<List<DogPark>> _fetchFromOverpass(
    double lat, double lng, http.Client c,
    {required bool clientProvided}) async {
  try {
    Object? lastError;
    for (final endpoint in overpassEndpoints) {
      try {
        final res = await c
            .post(
              Uri.parse(endpoint),
              headers: parkHttpHeaders,
              body: {'data': buildOverpassQuery(lat, lng)},
            )
            .timeout(parkFetchTimeout);
        if (res.statusCode != 200) {
          throw ParkFetchException('Overpass API エラー: ${res.statusCode}');
        }
        return parseOverpassResponse(res.body, lat, lng);
      } catch (e) {
        lastError = e;
      }
    }
    throw lastError ?? const ParkFetchException('公園情報を取得できませんでした');
  } finally {
    if (!clientProvided) c.close();
  }
}

// ------------------------------------------------------------ cache

String _cacheKey(double lat, double lng) =>
    'parks@${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';

List<DogPark>? _memParks;
String? _memKey;
DateTime _memAt = DateTime.fromMillisecondsSinceEpoch(0);
const String _kDiskCache = 'inutomo_park_cache';

Map<String, dynamic> dogParkToMap(DogPark p) => {
      'id': p.osmId,
      'name': p.name,
      'type': p.type,
      'lat': p.lat,
      'lng': p.lng,
      'km': p.distanceKm,
      'dog': p.dogRule,
      'feeFree': p.feeFreeKnown,
      'hours': p.openingHours,
    };

DogPark dogParkFromMap(Map<String, dynamic> m) => DogPark(
      osmId: m['id'] as String,
      name: m['name'] as String,
      type: m['type'] as String,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
      distanceKm: (m['km'] as num).toDouble(),
      dogRule: (m['dog'] as String?) ?? 'unknown',
      feeFreeKnown: (m['feeFree'] as bool?) ?? false,
      openingHours: m['hours'] as String?,
    );

Future<List<DogPark>?> _loadDiskCache(String key, DateTime now) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kDiskCache);
    if (raw == null) return null;
    final m = jsonDecode(raw) as Map<String, dynamic>;
    if (m['key'] != key) return null;
    final at = DateTime.tryParse(m['at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (now.isAfter(at.add(parkCacheTtl))) return null;
    final list = (m['parks'] as List)
        .map((e) => dogParkFromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list.isEmpty ? null : list;
  } catch (_) {
    return null;
  }
}

Future<void> _saveDiskCache(String key, List<DogPark> parks, DateTime at) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDiskCache, jsonEncode({
      'key': key,
      'at': at.toIso8601String(),
      'parks': parks.map(dogParkToMap).toList(),
    }));
  } catch (_) {
    // 保存失敗は無視（メモリキャッシュは有効）
  }
}

/// Overpass の JSON を DogPark の一覧（距離昇順）に変換する。
/// 純関数として切り出してテストできるようにしている。
List<DogPark> parseOverpassResponse(String body, double lat, double lng) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic> || decoded['elements'] is! List) {
    throw const ParkFetchException('不正なレスポンス形式です');
  }
  final parks = <DogPark>[];
  for (final e in decoded['elements'] as List) {
    if (e is! Map<String, dynamic>) continue;
    final elementId = e['id'];
    if (elementId == null) continue;
    final osmType = (e['type'] as String?) ?? '';
    final tags = (e['tags'] as Map?)?.cast<String, String>() ?? const {};
    // ドッグラン（leisure=dog_park）は一覧に含めない
    if (tags['leisure'] != 'park') continue;
    // 位置: node は直接持つ。way / relation は out center で付く center を使う
    double? pLat = (e['lat'] as num?)?.toDouble();
    double? pLng = (e['lon'] as num?)?.toDouble();
    final center = e['center'];
    if (center is Map) {
      pLat = (center['lat'] as num?)?.toDouble() ?? pLat;
      pLng = (center['lon'] as num?)?.toDouble() ?? pLng;
    }
    if (pLat == null || pLng == null) continue;
    // 犬同伴が明確に禁止（dog=no）の公園は除外
    final dog = tags['dog'] ?? 'unknown';
    if (dog == 'no') continue;
    parks.add(DogPark(
      osmId: '$osmType/$elementId',
      name: tags['name'] ?? '名称未登録の公園',
      type: 'park',
      lat: pLat,
      lng: pLng,
      distanceKm: haversineKm(lat, lng, pLat, pLng),
      dogRule: dog,
      openingHours: tags['opening_hours'],
    ));
  }
  parks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return parks.take(maxParks).toList(growable: false);
}

class ParkFetchException implements Exception {
  final String message;
  const ParkFetchException(this.message);
  @override
  String toString() => message;
}

/// 公園の「Googleマップで開く」URL（座標指定。迷わず正確な位置が開く）
String googleMapsUrlForPark(DogPark park) {
  return 'https://www.google.com/maps/search/?api=1&query=${park.lat},${park.lng}';
}

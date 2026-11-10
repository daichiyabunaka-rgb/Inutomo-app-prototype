import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import 'format.dart';

/// 「近くの公園を探す」機能のデータ層。
/// OpenStreetMap の Overpass API で現在地周辺の**公園**を取得する。
/// - ドッグラン（leisure=dog_park）は一覧に含めない
/// - 犬同伴が明確に禁止（dog=no）の公園は除外。
///   犬 OK（dog=yes / dog=leashed）の場合はその旨を表示する
/// 取得結果は現在地からの距離の昇順に並べる。

/// メインの Overpass サーバーが遅い・止まっている場合の代替ミラー
const List<String> overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

const int maxParks = 30;
const double searchRadiusKm = 5.0;
const Duration parkFetchTimeout = Duration(seconds: 20);

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
      'relation["leisure"="park"]["dog"!="no"]($bbox);'
      ');'
      'out center tags;';
}

/// 現在地周辺の公園を取得する（距離昇順）。
/// ドッグランは一覧に含めない。Overpass のミラーに順にフォールバックし、
/// すべて失敗したら例外を投げる。
Future<List<DogPark>> fetchDogParksNear(
  double lat,
  double lng, {
  http.Client? client,
}) async {
  final c = client ?? http.Client();
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
    if (client == null) c.close();
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

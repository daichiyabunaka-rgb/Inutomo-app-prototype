import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models.dart';
import '../services/app_config.dart';
import 'format.dart';

/// 「近くの公園を探す」機能のデータ層。
/// - GOOGLE_MAPS_API_KEY が指定されている場合: Google Places API
///   （Nearby Search, type=dog_park / park）で取得する
/// - それ以外 / 失敗時: OpenStreetMap の Overpass API で取得する
///   - leisure=dog_park（ドッグラン）: 有料（fee=yes）は一覧から除外
///   - leisure=park（公園）: 犬同伴が明確に禁止（dog=no）は除外。
///     犬 OK（dog=yes / dog=leashed）の場合はその旨を表示する
/// 取得結果は現在地からの距離の昇順に並べる。

/// メインの Overpass サーバーが遅い・止まっている場合の代替ミラー
const List<String> overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
];

/// Google Places API（Nearby Search）
const String placesNearbyUrl =
    'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

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
      'node["leisure"="dog_park"]($bbox);'
      'way["leisure"="dog_park"]($bbox);'
      'relation["leisure"="dog_park"]($bbox);'
      'node["leisure"="park"]["dog"!="no"]($bbox);'
      'way["leisure"="park"]["dog"!="no"]($bbox);'
      'relation["leisure"="park"]["dog"!="no"]($bbox);'
      ');'
      'out center tags;';
}

/// 現在地周辺の公園・ドッグランを取得する（距離昇順）。
/// GOOGLE_MAPS_API_KEY があれば Google Places、なければ Overpass
/// （ミラー順にフォールバック）。どちらも失敗したら例外を投げる。
Future<List<DogPark>> fetchDogParksNear(
  double lat,
  double lng, {
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    if (AppConfig.googleMapsApiKey.isNotEmpty) {
      try {
        return await _fetchFromGoogle(c, lat, lng);
      } catch (_) {
        // Google が失敗したら OSM にフォールバック
      }
    }
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

/// Google Places（Nearby Search）でドッグラン・公園を取得する。
/// 有料/無料の情報は Places API からは取れないため、
/// 無料表示（feeFreeKnown）は行わない。
Future<List<DogPark>> _fetchFromGoogle(
    http.Client c, double lat, double lng) async {
  final parks = <DogPark>[];
  for (final type in ['dog_park', 'park']) {
    final uri = Uri.parse(placesNearbyUrl).replace(queryParameters: {
      'location': '$lat,$lng',
      'radius': '${(searchRadiusKm * 1000).round()}',
      'type': type,
      'language': 'ja',
      'key': AppConfig.googleMapsApiKey,
    });
    final res =
        await c.get(uri, headers: parkHttpHeaders).timeout(parkFetchTimeout);
    if (res.statusCode != 200) {
      throw ParkFetchException('Places API エラー: ${res.statusCode}');
    }
    parks.addAll(
        parsePlacesResponse(res.body, lat, lng, isDogRun: type == 'dog_park'));
  }
  parks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  // 同じ場所・同じ名前の重複を除く
  final seen = <String>{};
  final unique = <DogPark>[];
  for (final p in parks) {
    final key = '${p.name}@${p.lat.toStringAsFixed(5)},${p.lng.toStringAsFixed(5)}';
    if (seen.add(key)) unique.add(p);
  }
  return unique.take(maxParks).toList(growable: false);
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
    final leisure = tags['leisure'];
    // 位置: node は直接持つ。way / relation は out center で付く center を使う
    double? pLat = (e['lat'] as num?)?.toDouble();
    double? pLng = (e['lon'] as num?)?.toDouble();
    final center = e['center'];
    if (center is Map) {
      pLat = (center['lat'] as num?)?.toDouble() ?? pLat;
      pLng = (center['lon'] as num?)?.toDouble() ?? pLng;
    }
    if (pLat == null || pLng == null) continue;

    if (leisure == 'dog_park') {
      // 有料のドッグランは一覧に出さない
      if (tags['fee'] == 'yes') continue;
      parks.add(DogPark(
        osmId: '$osmType/$elementId',
        name: tags['name'] ?? '名称未登録のドッグラン',
        type: 'dogrun',
        lat: pLat,
        lng: pLng,
        distanceKm: haversineKm(lat, lng, pLat, pLng),
        dogRule: 'yes',
        feeFreeKnown: tags['fee'] == 'no',
        openingHours: tags['opening_hours'],
      ));
    } else if (leisure == 'park') {
      // dog=no はクエリで除外しているが、レスポンス側でも同一ユーザー設定で守る
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

/// Google Places（Nearby Search）の JSON を DogPark の一覧に変換する。
/// 純関数として切り出してテストできるようにしている。
List<DogPark> parsePlacesResponse(
  String body,
  double lat,
  double lng, {
  required bool isDogRun,
}) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const ParkFetchException('不正なレスポンス形式です');
  }
  final status = decoded['status'] as String? ?? '';
  if (status != 'OK' && status != 'ZERO_RESULTS') {
    throw ParkFetchException('Places API status: $status');
  }
  final results = decoded['results'];
  if (results is! List) return const [];
  final parks = <DogPark>[];
  for (final e in results) {
    if (e is! Map<String, dynamic>) continue;
    final geometry = e['geometry'];
    if (geometry is! Map) continue;
    final loc = geometry['location'];
    if (loc is! Map) continue;
    final pLat = (loc['lat'] as num?)?.toDouble();
    final pLng = (loc['lng'] as num?)?.toDouble();
    if (pLat == null || pLng == null) continue;
    parks.add(DogPark(
      osmId: 'gplaces/${e['place_id'] ?? '${pLat}_$pLng'}',
      name: (e['name'] as String?)?.trim().isNotEmpty == true
          ? e['name'] as String
          : (isDogRun ? '名称未登録のドッグラン' : '名称未登録の公園'),
      type: isDogRun ? 'dogrun' : 'park',
      lat: pLat,
      lng: pLng,
      distanceKm: haversineKm(lat, lng, pLat, pLng),
      // Places API は犬の可否・料金の情報を持たない
      dogRule: isDogRun ? 'yes' : 'unknown',
      feeFreeKnown: false,
    ));
  }
  return parks;
}

/// 公園の「Googleマップで開く」URL（座標指定。迷わず正確な位置が開く）
String googleMapsUrlForPark(DogPark park) {
  return 'https://www.google.com/maps/search/?api=1&query=${park.lat},${park.lng}';
}

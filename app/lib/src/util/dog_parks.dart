import '../models.dart';

/// 「近くの公園を探す」機能のデータ層（プロトタイプ）。
/// 公園は現在地（anchor）からの相対距離で配置したシード。
/// 本開発では Google Places API（type=dog_park / park）または
/// OpenStreetMap の Overpass API で取得し、
/// Googleマップアプリへの遷移は標準URLスキーム（APIキー不要）で行う。
const List<DogPark> seedDogParks = [
  DogPark(
    id: 'p-central-dogrun',
    name: '中央公園 ドッグラン',
    type: 'dogrun',
    description: '小型犬・大型犬エリアが分かれた有料ドッグラン。土砂降り以外は毎日開放。',
    features: ['リードフリー', '小型犬エリア', '大型犬エリア', '飲水場', '駐車場'],
    northKm: 0.7,
    eastKm: 0.4,
  ),
  DogPark(
    id: 'p-riverside',
    name: '河川敷リバーサイド公園',
    type: 'park',
    description: '川沿いの広い芝生。散歩コースとして人気。リード着用必須。',
    features: ['散歩コース', '芝生', 'リード着用必須', '犬OK'],
    northKm: -0.4,
    eastKm: 1.2,
  ),
  DogPark(
    id: 'p-wanwan',
    name: 'わんわん公園',
    type: 'park',
    description: '地元の飼い主さんが集まる小さな公園。夕方は犬友達でにぎわう。',
    features: ['犬OK', 'ベンチ', '飲水場', 'トイレ'],
    northKm: 0.2,
    eastKm: -0.9,
  ),
  DogPark(
    id: 'p-hill',
    name: '丘陵自然公園',
    type: 'park',
    description: '起伏のある自然豊かな公園。しっかり歩けるので運動不足のワンちゃんに。',
    features: ['散歩コース', '木材チップ', '犬OK', '駐車場'],
    northKm: 1.4,
    eastKm: -0.6,
  ),
  DogPark(
    id: 'p-forest-run',
    name: '森のドッグラン',
    type: 'dogrun',
    description: '原生林に囲まれた無料のドッグラン。アジリティ道具もある。',
    features: ['リードフリー', '無料', 'アジリティ', '日陰'],
    northKm: -1.2,
    eastKm: -1.5,
  ),
  DogPark(
    id: 'p-sakura',
    name: '桜並木公園',
    type: 'park',
    description: '春は桜の名所。犬の散歩スポットとして地元で定番。',
    features: ['犬OK', '桜', '散歩コース', 'ベンチ'],
    northKm: -0.8,
    eastKm: 2.2,
  ),
];

const double _kmPerDegLat = 111.32;

/// 相対距離の公園リストを、現在地を中心とした lat/lng に変換したペア。
class PlacedPark {
  final DogPark park;
  final double lat;
  final double lng;
  const PlacedPark(this.park, this.lat, this.lng);
}

List<PlacedPark> placeDogParks(double anchorLat, double anchorLng) {
  final cos = anchorLat * 3.1415926535897932 / 180.0;
  final cosAbs = cos.abs().clamp(0.01, 1.0);
  return [
    for (final p in seedDogParks)
      PlacedPark(
        p,
        anchorLat + p.northKm / _kmPerDegLat,
        anchorLng + p.eastKm / (_kmPerDegLat * cosAbs),
      ),
  ];
}

/// 公園の「Googleマップで開く」URL（標準URLスキーム。APIキー不要）。
/// 名前で検索して最寄りの候補を開くため、本開発で Place ID を持つ
/// データソース（Google Places）に置き換えた際は
/// `https://www.google.com/maps/search/?api=1&query=<Place ID>` を使う。
String googleMapsUrlForPark(String parkName) {
  final encoded = Uri.encodeComponent(parkName);
  return 'https://www.google.com/maps/search/?api=1&query=$encoded';
}

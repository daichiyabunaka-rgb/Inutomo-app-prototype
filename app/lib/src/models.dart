import 'package:flutter/material.dart';

/// 募集ジャンル
class Genre {
  final String id;
  final String label;
  final IconData icon;
  const Genre(this.id, this.label, this.icon);
}

const List<Genre> genres = [
  Genre('sanpo', 'お散歩', Icons.directions_walk),
  Genre('dogrun', 'ドッグラン', Icons.pets),
  Genre('dogcafe', 'ドッグカフェ', Icons.local_cafe),
];

Genre genreById(String id) => genres.firstWhere((g) => g.id == id);

/// ともつく！シリーズ（趣味特化型マッチングアプリ群）の共通定義。
/// 犬とも！・釣りとも！は同一のSupabaseプロジェクト・アカウントを共有し、
/// このapp_idで各アプリのデータを識別する。
const Map<String, String> tomoTskuAppNames = {
  'meshitomo': '飯とも！',
  'inutomo': '犬とも！',
  'tsuritomo': '釣りとも！',
  'nekotomo': 'ニーアキャット',
};

/// 興味カテゴリ。
/// `interestCategories` は初期セット（デフォルト）。ユーザーは自由に
/// カテゴリを追加でき（AppState.categoryRegistry）、Supabase モードでは
/// 全ユーザーに共有される。
class InterestCategory {
  final String id;
  final String label;
  final IconData icon;
  const InterestCategory(this.id, this.label, this.icon);
}

const List<InterestCategory> interestCategories = [
  InterestCategory('sanpo', 'お散歩', Icons.directions_walk),
  InterestCategory('dogrun', 'ドッグラン', Icons.pets),
  InterestCategory('dogcafe', 'ドッグカフェ', Icons.local_cafe),
  InterestCategory('training', 'しつけ・トレーニング', Icons.school),
  InterestCategory('sports', 'アジリティ・ドッグスポーツ', Icons.sports),
  InterestCategory('photo', '愛犬撮影', Icons.camera_alt),
  InterestCategory('goods', 'グッズ・おやつ研究', Icons.shopping_basket),
  InterestCategory('travel', 'お出かけ・旅行', Icons.luggage),
  InterestCategory('health', '健康・動物病院', Icons.medical_services),
  InterestCategory('grooming', 'トリミング・お手入れ', Icons.content_cut),
  InterestCategory('rescue', '保護犬・里親活動', Icons.volunteer_activism),
  InterestCategory('wanko', '犬友達・多頭飼い', Icons.diversity_1),
];

/// カスタムカテゴリのアイコン候補（名前でDB保存するため定数マップ）。
/// 本アプリは犬に特化するため、アイコンも犬・ペット系のみとする
/// （その他の趣味は別アプリで展開する方針）。
const Map<String, IconData> categoryIconChoices = {
  'pets': Icons.pets,
  'walk': Icons.directions_walk,
  'park': Icons.park,
  'grass': Icons.grass,
  'cafe': Icons.local_cafe,
  'ball': Icons.sports_baseball,
  'toy': Icons.toys,
  'camera': Icons.camera_alt,
  'food': Icons.restaurant,
  'cut': Icons.content_cut,
  'medical': Icons.medical_services,
  'car': Icons.directions_car,
  'hotel': Icons.hotel,
  'heart': Icons.favorite,
  'bag': Icons.shopping_bag,
};

/// アイコン名から IconData を引く（未登録の名前はデフォルトを返す）
IconData categoryIconByName(String? name) =>
    categoryIconChoices[name] ?? Icons.pets;

/// プロトタイプ用のモック現在地（本開発では端末の GPS + geohash に置き換える）
class MockLocation {
  final String id;
  final String name;
  final double lat;
  final double lng;
  const MockLocation(this.id, this.name, this.lat, this.lng);
}

const List<MockLocation> mockLocations = [
  MockLocation('tokyo', '東京駅', 35.6812, 139.7671),
  MockLocation('yurakucho', '有楽町', 35.6748, 139.7629),
  MockLocation('akiba', '秋葉原', 35.7023, 139.7745),
  MockLocation('shibuya', '渋谷', 35.6580, 139.7016),
  MockLocation('shinjuku', '新宿', 35.6896, 139.7006),
  MockLocation('shinagawa', '品川', 35.6285, 139.7394),
];

/// 近くの公園・ドッグラン（「近くの公園を探す」機能）。
/// 実データは OpenStreetMap（Overpass API）から現在地周辺で取得する。
/// 有料（fee=yes）のドッグランは一覧から除外する。
class DogPark {
  final String osmId; // 例: 'way/12345'
  final String name;
  final String type; // 'dogrun'（ドッグラン） | 'park'（公園）
  final double lat;
  final double lng;
  final double distanceKm; // 現在地からの距離
  final String dogRule; // 'yes' | 'leashed' | 'no' | 'unknown'
  final bool
      feeFreeKnown; // fee タグで無料と明記されているか（ドッグラン表示用）
  final String? openingHours;

  const DogPark({
    required this.osmId,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
    required this.distanceKm,
    this.dogRule = 'unknown',
    this.feeFreeKnown = false,
    this.openingHours,
  });

  bool get isDogRun => type == 'dogrun';
}

class AppUser {
  final String id;
  final String nickname;
  final String decade; // 例: '20代'。ビジネスユーザーは '経営者'
  final String gender; // 'male' | 'female' | 'undisclosed'
  final String iconCategoryId; // 趣味アイコン（顔画像は禁止）
  final String? iconImagePath; // 端末内に保存した投稿アイコン画像（あれば優先表示）
  final List<String> interestIds;
  final String bio;
  final double lat;
  final double lng;
  final String? websiteUrl; // 公開URL（例: 店のホームページ）
  final String? snsNote; // SNS（例: 'X: @inutomo_official / IG: inutomo'）
  final String? phone; // ビジネスユーザー（店舗）の電話番号。タップで発信
  final String? appSource; // このプロフィール行の由来アプリ（自分のアプリなら null）
  final bool crossAppVisible; // ともつく！全体に表示する設定（この行の値）

  const AppUser({
    required this.id,
    required this.nickname,
    required this.decade,
    required this.gender,
    required this.iconCategoryId,
    required this.interestIds,
    required this.bio,
    required this.lat,
    required this.lng,
    this.iconImagePath,
    this.websiteUrl,
    this.snsNote,
    this.phone,
    this.appSource,
    this.crossAppVisible = false,
  });

  String get genderLabel => const {'male': '男性', 'female': '女性'}.containsKey(gender)
      ? const {'male': '男性', 'female': '女性'}[gender]!
      : '非公開';

  bool get isBusiness => false;

  /// 他のともつく！アプリ由来のプロフィール行か
  bool get isOtherApp => appSource != null;

  /// 由来アプリの表示名（例: '釣りとも！'）
  String get appSourceLabel =>
      isOtherApp ? (tomoTskuAppNames[appSource] ?? appSource!) : '';

  /// 位置だけ変えたコピーを返す
  AppUser withPosition(double newLat, double newLng) {
    return AppUser(
      id: id,
      nickname: nickname,
      decade: decade,
      gender: gender,
      iconCategoryId: iconCategoryId,
      interestIds: interestIds,
      bio: bio,
      lat: newLat,
      lng: newLng,
      iconImagePath: iconImagePath,
      websiteUrl: websiteUrl,
      snsNote: snsNote,
      phone: phone,
      appSource: appSource,
      crossAppVisible: crossAppVisible,
    );
  }
}

/// ビジネスユーザー（店舗。一般ユーザー登録と分離された登録フローで作られる）
class BusinessUser extends AppUser {
  final String storeType; // 例: 'ドッグラン'

  const BusinessUser({
    required super.id,
    required super.nickname,
    required super.decade,
    required super.gender,
    required super.iconCategoryId,
    required super.interestIds,
    required super.bio,
    required super.lat,
    required super.lng,
    required this.storeType,
    super.iconImagePath,
    super.websiteUrl,
    super.snsNote,
    super.phone,
    super.appSource,
    super.crossAppVisible,
  });

  @override
  bool get isBusiness => true;

  @override
  AppUser withPosition(double newLat, double newLng) {
    return BusinessUser(
      id: id,
      nickname: nickname,
      decade: decade,
      gender: gender,
      iconCategoryId: iconCategoryId,
      interestIds: interestIds,
      bio: bio,
      lat: newLat,
      lng: newLng,
      storeType: storeType,
      iconImagePath: iconImagePath,
      websiteUrl: websiteUrl,
      snsNote: snsNote,
      phone: phone,
      appSource: appSource,
      crossAppVisible: crossAppVisible,
    );
  }
}

enum RecStatus { active, fulfilled, expired, cancelled }

class Recruitment {
  final String id;
  final String hostId;
  final String genreId;
  final String title;
  final String body;
  final String meetup;
  final int capacity;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> memberIds; // host を含む

  const Recruitment({
    required this.id,
    required this.hostId,
    required this.genreId,
    required this.title,
    required this.body,
    required this.meetup,
    required this.capacity,
    required this.createdAt,
    required this.expiresAt,
    required this.memberIds,
  });

  bool get isFull => memberIds.length >= capacity;

  bool isActiveAt(DateTime now) =>
      now.isBefore(expiresAt) && !isFull && memberIds.isNotEmpty;

  int get remainingSlots => capacity - memberIds.length;

  RecStatus statusAt(DateTime now) {
    if (isFull) return RecStatus.fulfilled;
    if (!now.isBefore(expiresAt)) return RecStatus.expired;
    return RecStatus.active;
  }
}

enum JoinStatus { pending, accepted, declined }

class JoinApplication {
  final String id;
  final String recruitmentId;
  final String applicantId;
  final String message;
  JoinStatus status;
  final DateTime createdAt;

  JoinApplication({
    required this.id,
    required this.recruitmentId,
    required this.applicantId,
    required this.message,
    required this.status,
    required this.createdAt,
  });
}

class ChatRoom {
  final String id;
  final String recruitmentId; // DM・コミュニティの場合は空文字
  final List<String> memberIds;
  final DateTime createdAt;
  final String type; // 'group' | 'dm' | 'community'
  final String? communityId; // コミュニティチャットの場合

  ChatRoom({
    required this.id,
    required this.recruitmentId,
    required this.memberIds,
    required this.createdAt,
    this.type = 'group',
    this.communityId,
  });

  bool get isDm => type == 'dm';

  bool get isCommunity => type == 'community';
}

/// コミュニティ（クラブ・イベント企画・店舗のファンコミュニティ）。
/// 誰でも作成でき、参加するとコミュニティチャットが開ける（FR-6-1〜6-3）。
class Community {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? linkedStore; // 店舗ファンコミュニティの場合の店舗名
  final DateTime createdAt;
  final Set<String> memberIds;

  Community({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.linkedStore,
    required this.createdAt,
    required this.memberIds,
  });

  Community copyWith({
    Set<String>? memberIds,
    String? name,
    String? description,
  }) {
    return Community(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      linkedStore: linkedStore,
      createdAt: createdAt,
      memberIds: memberIds ?? this.memberIds,
    );
  }
}

/// コミュニティ内で企画されるイベント・クラブ
class CommunityEvent {
  final String id;
  final String communityId;
  final String hostId;
  final String title;
  final String body;
  final String eventTime; // ベータでは自由記述（例: '3/14 19:00〜'）
  final String locationName;
  final int capacity;
  final DateTime createdAt;
  final Set<String> participantIds;

  CommunityEvent({
    required this.id,
    required this.communityId,
    required this.hostId,
    required this.title,
    required this.body,
    required this.eventTime,
    required this.locationName,
    required this.capacity,
    required this.createdAt,
    required this.participantIds,
  });

  bool get isFull => participantIds.length >= capacity;

  CommunityEvent copyWith({Set<String>? participantIds}) {
    return CommunityEvent(
      id: id,
      communityId: communityId,
      hostId: hostId,
      title: title,
      body: body,
      eventTime: eventTime,
      locationName: locationName,
      capacity: capacity,
      createdAt: createdAt,
      participantIds: participantIds ?? this.participantIds,
    );
  }
}

/// 保護犬・迷子犬の登録（近隣での情報共有）。
/// kind: 'protected' = 見つけて保護したワンちゃん
///       'lost'      = 手元からいなくなったワンちゃん
/// 譲渡・里親探しは行わない（自治体・保護団体の正式な手続きへ誘導する設計）。
class ProtectedDog {
  final String id;
  final String reporterId;
  final String kind; // 'protected' | 'lost'
  final String dogDescription; // 犬種・大きさ・体色など
  final String areaName; // 保護・目撃・最後に見た場所
  final String detail; // 特徴・状況の自由記述
  final String? photoPath; // 投稿写真（端末内パス or 公開URL）
  final double lat;
  final double lng;
  final DateTime createdAt;
  bool resolved; // 解決済み（飼い主と再会、保護先へ引き取られた等）

  ProtectedDog({
    required this.id,
    required this.reporterId,
    required this.kind,
    required this.dogDescription,
    required this.areaName,
    required this.detail,
    required this.lat,
    required this.lng,
    required this.createdAt,
    this.photoPath,
    this.resolved = false,
  });

  bool get isProtected => kind == 'protected';

  bool get isLost => kind == 'lost';
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId; // system の場合 'system'
  final String body;
  final DateTime sentAt;
  final bool isSystem;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.body,
    required this.sentAt,
    this.isSystem = false,
  });
}

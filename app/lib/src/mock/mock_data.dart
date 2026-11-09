import 'dart:math' as math;

import '../models.dart';

/// モックユーザーは「anchor（中心点）からの相対距離」で配置する。
/// anchor には実 GPS で取得した現在地が入り、どこにいても近くの飯とも候補が並ぶ。
class _MockSpec {
  final String id;
  final String nickname;
  final String decade;
  final String gender;
  final String iconCategoryId;
  final List<String> interestIds;
  final String bio;
  final double northKm; // anchor からの北方向距離
  final double eastKm; // anchor からの東方向距離

  const _MockSpec(this.id, this.nickname, this.decade, this.gender,
      this.iconCategoryId, this.interestIds, this.bio, this.northKm,
      this.eastKm);
}

const List<_MockSpec> _specs = [
  _MockSpec(
    'u-ramen-ken',
    'ラーメン巡り健',
    '30代',
    'male',
    'ramen',
    ['ramen', 'izakaya', 'spicy'],
    '週4でラーメン。二郎系から清湯まで。ひとり飯もいいけど一緒に行きたい。',
    0.6,
    0.2,
  ),
  _MockSpec(
    'u-yakiniku-mi',
    '焼肉のみゆ',
    '20代',
    'female',
    'yakiniku',
    ['yakiniku', 'cafe', 'sweets'],
    'ハラミ推し。甘だれ派。平日の夜に強い。',
    -0.3,
    -0.1,
  ),
  _MockSpec(
    'u-cafe-yam',
    'カフェ巡りヤム',
    '20代',
    'undisclosed',
    'cafe',
    ['cafe', 'sweets', 'brunch'],
    '新刊とともにブランチ。日曜の午後が好き。',
    0.15,
    -0.4,
  ),
  _MockSpec(
    'u-spicy-tan',
    '激辛タヌキ',
    '40代',
    'male',
    'spicy',
    ['spicy', 'ethnic', 'ramen'],
    '辛さは相談可。麻婆麺とタイ料理をよく食べる。',
    -0.7,
    0.5,
  ),
  _MockSpec(
    'u-izakaya-ryo',
    'ちょい飲みリョウ',
    '30代',
    'undisclosed',
    'izakaya',
    ['izakaya', 'sushi', 'pasta'],
    '仕事帰りの1杯と小皿が好き。1軒目で帰る派。',
    1.2,
    -0.9,
  ),
  _MockSpec(
    'u-sweets-hana',
    'スイーツ編集はな',
    '20代',
    'female',
    'sweets',
    ['sweets', 'cafe', 'brunch'],
    'パンケーキとシュークリームを研究中。甘いものは別腹。',
    -1.1,
    1.0,
  ),
  _MockSpec(
    'u-sushi-masa',
    '回らない幹事マサ',
    '50代以上',
    'male',
    'sushi',
    ['sushi', 'izakaya', 'yakiniku'],
    '気軽に誘える飯ともが欲しくて始めました。幹事は慣れています。',
    0.9,
    0.35,
  ),
  _MockSpec(
    'u-burger-nana',
    'バーガーなな',
    '20代',
    'female',
    'burger',
    ['burger', 'pizza', 'cafe'],
    '土曜のお昼にハンバーガー。月1ペースで定点観測中。',
    0.45,
    -1.3,
  ),
];

class _BusinessSpec {
  final String id;
  final String nickname;
  final String iconCategoryId;
  final String storeType;
  final String bio;
  final double northKm;
  final double eastKm;

  const _BusinessSpec(this.id, this.nickname, this.iconCategoryId,
      this.storeType, this.bio, this.northKm, this.eastKm);
}

const List<_BusinessSpec> _businessSpecs = [
  _BusinessSpec(
    'b-izakaya-noren',
    '居酒屋 のれん',
    'izakaya',
    '居酒屋',
    '常連さんが集まる小さな居酒屋。ひとり飲みも大歓迎。',
    0.8,
    0.9,
  ),
  _BusinessSpec(
    'b-ramen-niban',
    'ラーメン二番',
    'ramen',
    'ラーメン店',
    'とんこつと背脂が看板。気負わず食べられる一杯を。',
    -0.5,
    1.1,
  ),
  _BusinessSpec(
    'b-yakiniku-hanamichi',
    '焼肉 はなみち',
    'yakiniku',
    '焼肉店',
    '煙で顔が見えない距離感も、ときには大事。',
    1.5,
    -0.6,
  ),
  _BusinessSpec(
    'b-cafe-morning',
    'カフェ・ド・モーニング',
    'cafe',
    'カフェ',
    '読書する人、勉強する人、ぼんやりする人、全員ウェルカム。',
    -1.4,
    -0.8,
  ),
];

const double _kmPerDegLat = 111.32;

AppUser _specToUser(_MockSpec s, double anchorLat, double anchorLng) {
  final cos =
      math.cos(anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return AppUser(
    id: s.id,
    nickname: s.nickname,
    decade: s.decade,
    gender: s.gender,
    iconCategoryId: s.iconCategoryId,
    interestIds: s.interestIds,
    bio: s.bio,
    lat: anchorLat + s.northKm / _kmPerDegLat,
    lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
  );
}

BusinessUser _specToBusiness(
    _BusinessSpec s, double anchorLat, double anchorLng) {
  final cos =
      math.cos(anchorLat * math.pi / 180.0).abs().clamp(0.01, 1.0);
  return BusinessUser(
    id: s.id,
    nickname: s.nickname,
    decade: '経営者',
    gender: 'undisclosed',
    iconCategoryId: s.iconCategoryId,
    interestIds: const [],
    bio: s.bio,
    lat: anchorLat + s.northKm / _kmPerDegLat,
    lng: anchorLng + s.eastKm / (_kmPerDegLat * cos),
    storeType: s.storeType,
  );
}

/// 現在地を中心にモックユーザー（一般 + ビジネス）を配置する
List<AppUser> buildMockUsers(double anchorLat, double anchorLng) {
  return [
    for (final s in _specs) _specToUser(s, anchorLat, anchorLng),
    for (final s in _businessSpecs) _specToBusiness(s, anchorLat, anchorLng),
  ];
}

/// シード募集（起動時刻からの残り時間で作るので、いつ開いても「今から」感が出る）。
/// host は generalUsers（モック一般ユーザー）から id で引く。
List<Recruitment> seedRecruitments(DateTime now, List<AppUser> generalUsers) {
  Recruitment make({
    required String hostId,
    required String genreId,
    required String title,
    required String body,
    required String meetup,
    required int capacity,
    required int minutesLeft,
  }) {
    return Recruitment(
      id: 'r-$hostId',
      hostId: hostId,
      genreId: genreId,
      title: title,
      body: body,
      meetup: meetup,
      capacity: capacity,
      createdAt: now.subtract(const Duration(minutes: 15)),
      expiresAt: now.add(Duration(minutes: minutesLeft)),
      memberIds: [hostId],
    );
  }

  return [
    make(
      hostId: 'u-ramen-ken',
      genreId: 'meshi',
      title: '今夜19時、近くの二郎系行きませんか',
      body: 'ラーメン好きなら誰でも大歓迎。初めてでもOK。食べ終わったら即解散でも構いません。',
      meetup: '駅の北口',
      capacity: 3,
      minutesLeft: 105,
    ),
    make(
      hostId: 'u-yakiniku-mi',
      genreId: 'nomi',
      title: '19:30 焼肉、あと1人',
      body: '仕事帰りです。ハラミとレバーを頼む予定。ゆるく飲めます。',
      meetup: '北口改札',
      capacity: 3,
      minutesLeft: 70,
    ),
    make(
      hostId: 'u-cafe-yam',
      genreId: 'cafe',
      title: '日曜ブランチ、パンケーキどうですか',
      body: '新しくできたカフェを開拓したい。読書しながらでも。',
      meetup: '中央口',
      capacity: 4,
      minutesLeft: 160,
    ),
    make(
      hostId: 'u-spicy-tan',
      genreId: 'meshi',
      title: '激辛麻婆豆腐、ついてこれる人',
      body: '四川料理の店を予約しました。辛さは調整できるので初心者もどうぞ。',
      meetup: '駅の西口',
      capacity: 2,
      minutesLeft: 95,
    ),
    make(
      hostId: 'u-izakaya-ryo',
      genreId: 'nomi',
      title: '明日が休みのひと、ちょい飲みしませんか',
      body: '串とハイボールの店。2軒目はなしの予定です。',
      meetup: '南口',
      capacity: 4,
      minutesLeft: 130,
    ),
    make(
      hostId: 'u-sushi-masa',
      genreId: 'meshi',
      title: 'お寿司のランチ、ご一緒に',
      body: '一人だとランチセットしか頼みませんが、皆だと色々頼れます。',
      meetup: '改札前',
      capacity: 3,
      minutesLeft: 45,
    ),
  ];
}

/// モックの返信候補（デモの自動応答に使う。本開発では Supabase Realtime に置換）
const List<String> mockReplies = [
  'よろしくお願いします！',
  '時間と場所、助かります。',
  '楽しみです。ちょっと先行って席を取っておきますね。',
  'このお店ずっと気になっていました。',
];

/// モックの応募メッセージ
const List<String> mockApplyMessages = [
  '参加したいです！ひとり飯が多かったので嬉しいです。',
  '近くにいたので飛び入りでも大丈夫ですか？',
  'このお店ずっと気になってました。',
];

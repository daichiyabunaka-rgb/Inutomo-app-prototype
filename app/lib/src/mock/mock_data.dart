import 'dart:math' as math;

import '../models.dart';

/// モックユーザーは「anchor（中心点）からの相対距離」で配置する。
/// anchor には実 GPS で取得した現在地が入り、どこにいても近くの犬とも候補が並ぶ。
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
    'u-shiba-moku',
    '柴犬のもくのパパ',
    '30代',
    'male',
    'sanpo',
    ['sanpo', 'dogrun', 'photo'],
    '柴犬のもく（男の子・4歳）と朝昼夜の散歩が日課。休日はドッグラン遠征中。',
    0.6,
    0.2,
  ),
  _MockSpec(
    'u-toypoodle-aoi',
    'トイプードル藍',
    '20代',
    'female',
    'dogcafe',
    ['dogcafe', 'grooming', 'photo'],
    'トイプードルの藍（女の子・2歳）。トリミングとカフェテラスが好き。',
    -0.3,
    -0.1,
  ),
  _MockSpec(
    'u-golden-rin',
    'ゴールデンのリン母',
    '40代',
    'female',
    'dogrun',
    ['dogrun', 'training', 'wanko'],
    'ゴールデンレトリバーのリン（男の子・6歳）。大型犬でも優しく遊べます。',
    0.15,
    -0.4,
  ),
  _MockSpec(
    'u-corgi-taro',
    'コーギー飼いのタロ',
    '30代',
    'undisclosed',
    'sanpo',
    ['sanpo', 'sports', 'goods'],
    'コーギーのぷく（女の子・3歳）。アジリティに興味あり。おやつ研究もしてます。',
    -0.7,
    0.5,
  ),
  _MockSpec(
    'u-chihuahua-nana',
    'チワワとのお散歩なな',
    '20代',
    'undisclosed',
    'sanpo',
    ['sanpo', 'health', 'wanko'],
    'チワワのちょこ（男の子・8歳）。シニア犬の健康管理について話したい。',
    1.2,
    -0.9,
  ),
  _MockSpec(
    'u-rescue-kai',
    '保護犬暮らしの櫂',
    '40代',
    'male',
    'rescue',
    ['rescue', 'training', 'sanpo'],
    '保護犬から迎えたラブラドルのそら（女の子・2歳）。じっくり信頼を育てる毎日。',
    -1.1,
    1.0,
  ),
  _MockSpec(
    'u-shibainu-masa',
    '柴犬二頭飼いマサ',
    '50代以上',
    'male',
    'wanko',
    ['wanko', 'dogrun', 'travel'],
    '柴犬のこまめ（5歳）とごま（3歳）の二頭飼い。犬連れ旅行の計画が趣味。',
    0.9,
    0.35,
  ),
  _MockSpec(
    'u-pome-yui',
    'ポメラニアン柚衣',
    '20代',
    'female',
    'photo',
    ['photo', 'dogcafe', 'goods'],
    'ポメラニアンのゆずむ（女の子・1歳）。愛犬の撮影のためにカメラを買い足しました。',
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
    'b-dogrun-wanpluza',
    'ドッグラン わんぷらざ',
    'dogrun',
    'ドッグラン',
    '小型犬・大型犬エリアが分かれた広めのドッグラン。初めての子もゆっくり慣らせます。',
    0.8,
    0.9,
  ),
  _BusinessSpec(
    'b-cafe-mofu',
    'ドッグカフェ もふもふ',
    'dogcafe',
    'ドッグカフェ',
    '犬連れOKのテラス席とドッグメニューあり。飼い主さん同士の交流の場にも。',
    -0.5,
    1.1,
  ),
  _BusinessSpec(
    'b-salon-pokopoko',
    'ペットサロン ぽこぽこ',
    'grooming',
    'ペットサロン・トリミング',
    'ワンちゃんのペースを最優先にしたトリミングとシャンプー。歯磨きもお任せください。',
    1.5,
    -0.6,
  ),
  _BusinessSpec(
    'b-vet-aibuki',
    'あいぶき動物病院',
    'health',
    '動物病院',
    '予防接種・健康診断のほか、少し気になることも気軽に相談できる病院です。',
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

/// 現在地を中心にモックユーザー（一般 + ビジネス）を配置する。
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
      hostId: 'u-shiba-moku',
      genreId: 'sanpo',
      title: '今から19時、近くの公園でお散歩しませんか',
      body: '柴犬のもくと30分ほど歩く予定。初めてでも気軽にどうぞ。犬種は問いません。',
      meetup: '中央公園の入り口',
      capacity: 3,
      minutesLeft: 105,
    ),
    make(
      hostId: 'u-golden-rin',
      genreId: 'dogrun',
      title: 'ドッグラン、あと1組どうですか',
      body: 'リンは大型犬ですが穏やかに遊べます。女性の飼い主さんも歓迎。',
      meetup: 'ドッグラン わんぷらざ 玄関',
      capacity: 3,
      minutesLeft: 70,
    ),
    make(
      hostId: 'u-toypoodle-aoi',
      genreId: 'dogcafe',
      title: '日曜午後、ドッグカフェで一息どうですか',
      body: '犬連れOKのカフェを開拓したい。テラス席でのんびりできれば。',
      meetup: '駅の東口',
      capacity: 4,
      minutesLeft: 160,
    ),
    make(
      hostId: 'u-corgi-taro',
      genreId: 'sanpo',
      title: 'コーギーと一緒に、川沿いをお散歩',
      body: '川沿いコースを1時間ほど歩く予定。アジリティに興味がある方と情報交換もしたい。',
      meetup: 'リバーサイド公園 駐車場',
      capacity: 2,
      minutesLeft: 95,
    ),
    make(
      hostId: 'u-chihuahua-nana',
      genreId: 'sanpo',
      title: 'シニア犬とゆる〜い夜散歩、ご一緒に',
      body: 'チワワのちょこのペースに合わせてゆっくり。ちょっと健康の話もできれば。',
      meetup: 'わんわん公園 前',
      capacity: 4,
      minutesLeft: 130,
    ),
    make(
      hostId: 'u-shibainu-masa',
      genreId: 'dogrun',
      title: '柴犬二頭とドッグランへ。犬連れ旅行の話もしませんか',
      body: '犬連れで行ける宿の情報交換をしたいです。初心者も大歓迎。',
      meetup: '森のドッグラン 正面ゲート',
      capacity: 3,
      minutesLeft: 45,
    ),
  ];
}

/// モックの返信候補（デモの自動応答に使う。本開発では Supabase Realtime に置換）
const List<String> mockReplies = [
  'よろしくお願いします！',
  'ワンちゃんの様子、楽しみです。',
  '先に着いて場所を取っておきますね。',
  'この公園ずっと気になっていました。',
];

/// モックの応募メッセージ
const List<String> mockApplyMessages = [
  '参加したいです！うちの子も犬友達を探していました。',
  'お散歩仲間がいなくて困っていたので嬉しいです。',
  'この公園、近くに住んでいてよく通っています。',
];

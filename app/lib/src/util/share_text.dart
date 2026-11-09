/// アプリ招待メッセージの組み立て。
/// 純関数として切り出してテストできるようにしている。
/// リリース後は URL をストアの配布ページ（Google Play / App Store）に差し替え、
/// 招待コード（?ref=userId）を付けて、招待経由の登録で両者を繋げる予定（v2）。
const String kAppUrl =
    'https://github.com/daichiyabunaka-rgb/Inutomo-app-prototype';

String inviteText(String nickname) {
  return '一緒に「犬とも！」を使いませんか？\n'
      '飼い主さん同士でつながる犬とも探しアプリ。顔ではなく中身で、'
      '近くの人と今からワンちゃんのお散歩やドッグランに行けるよ。\n'
      '$nicknameも参加しています。一般利用は完全無料です。\n'
      '$kAppUrl';
}

/// 特定の募集に誘う共有文（「この募集に参加しませんか」でも SNS 共有できる）
String recruitmentShareText(String title, String meetup) {
  return '一緒にお散歩しませんか？「犬とも！」で募集しています。\n'
      '「$title」（集合: $meetup）\n'
      '$kAppUrl';
}

/// ビジネスユーザーが他のビジネスユーザー（同業の店舗経営者）に送る紹介・招待文。
/// ビジネスユーザー同士のつながり（同業者との情報交換）を生むための共有。
String businessInviteText(String myStoreName, String myStoreType) {
  return '近くの飼い主さんと直接つながれるアプリ「犬とも！」を'
      '使いませんか？\n'
      '$myStoreType「$myStoreName」も参加しています。\n'
      '一般ユーザーもビジネスユーザーも、ベータ期間中は無料でご利用いただけます。\n'
      '$kAppUrl';
}

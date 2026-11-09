import '../models.dart';

/// AI接客のデモ応答ロジック（プロトタイプ用のモック）。
/// 本開発では LLM API に置き換える。このロジックは店舗業態と
/// ユーザーの興味カテゴリから_recommend を選ぶ最低限のルールベース。
class AiConcierge {
  /// 最初の挨拶（店舗の口調 + ユーザーの興味を踏まえる）
  String greeting(AppUser me, BusinessUser store) {
    final interest = me.interestIds.isNotEmpty ? me.interestIds.first : null;
    final label = interest == null ? null : _categoryLabel(interest);
    final base = '${_opener(store)}'
        '${me.nickname}さん、${store.nickname}（${store.storeType}）のAI接客です。';
    if (label == null) {
      return '$base 何か聞きたいことがあればどうぞ。';
    }
    return '$base $labelがお好みなんですね。'
        'うちの${_recommend(store)}がおすすめです。';
  }

  /// 店舗タイプごとの口調（本開発では LLM に店舗キャラ設定を渡して生成する）
  String _opener(BusinessUser store) {
    switch (store.storeType) {
      case '居酒屋':
        return 'いらっしゃい、今日もお疲れさんでした。';
      case 'ラーメン店':
        return 'ようこそ。旨い一杯でお待ちしてます。';
      case '焼肉店':
        return 'いらっしゃいませ！お肉、今が一番いい状態です。';
      case 'カフェ':
        return 'こんにちは。ごゆっくりどうぞ。';
      default:
        return 'いらっしゃいませ。';
    }
  }

  /// ユーザー発話への応答
  String reply(String input, AppUser me, BusinessUser store) {
    final text = input.replaceAll(RegExp(r'\s'), '');
    if (text.contains('予約')) {
      return 'ありがとうございます。19時以降でしたらカウンターに空きが'
          'ありそうです。人数と時間をメモしておきますね。'
          '（デモのため実際の予約機能は v1.5 で提供します）';
    }
    if (text.contains('おすすめ') || text.contains('オススメ')) {
      return '今回は${_recommend(store)}がおすすめです。'
          '季節の食材も入荷しています。苦手なものがあれば教えてください。';
    }
    if (text.contains('席')) {
      return 'カウンター席が空いています。おひとり様でもゆっくり'
          'いただけます。テーブル席をご希望でしたら奥もご用意できます。';
    }
    if (text.contains('終電')) {
      return 'ラストオーダーは22:30を予定しています。'
          '終電の時間を教えていただければ、それに合わせたペースでご案内します。';
    }
    if (text.contains('何時') || text.contains('営業時間')) {
      return '本日は17:00〜23:00で営業しております。'
          '混雑しやすい時間帯は19〜21時です。（デモの固定値です）';
    }
    if (text.contains('何人') || text.contains('人数')) {
      return '4名様まででしたら楽にご案内できます。'
          '5名様以上はご相談ください。';
    }
    return '承知しました。「おすすめ」「席」「営業時間」「予約」など、'
        '気になることを聞いていただければ答えます。';
  }

  String _recommend(BusinessUser store) {
    switch (store.storeType) {
      case '居酒屋':
        return '本日仕入れの刺身盛り';
      case 'ラーメン店':
        return 'とんこつ背脂の二番ラーメン';
      case '焼肉店':
        return 'ハラミの厚切り';
      case 'カフェ':
        return '焼き菓子のセット';
      default:
        return '看板メニュー';
    }
  }

  String _categoryLabel(String id) {
    const labels = {
      'izakaya': '居酒屋めぐり',
      'yakiniku': '焼肉',
      'ramen': 'ラーメン',
      'cafe': 'カフェ',
      'sweets': 'スイーツ',
      'sushi': '寿司',
      'pasta': 'パスタ',
      'pizza': 'ピザ',
      'burger': 'ハンバーガー',
      'spicy': '激辛',
      'ethnic': 'エスニック',
      'brunch': 'ブランチ',
    };
    return labels[id] ?? 'グルメ';
  }
}

/// グローバルインスタンス（本開発では DI / LLM API クライアントに置き換える）
final AiConcierge aiConcierge = AiConcierge();

import '../models.dart';

/// AI接客のデモ応答ロジック（プロトタイプ用のモック）。
/// 本開発では LLM API に置き換える。このロジックは店舗業態と
/// ユーザーの興味カテゴリからおすすめを案内する最低限のルールベース。
class AiConcierge {
  /// 最初の挨拶（店舗の口調 + ユーザーの興味を踏まえる）
  String greeting(AppUser me, BusinessUser store) {
    final interest = me.interestIds.isNotEmpty ? me.interestIds.first : null;
    final label = interest == null ? null : _categoryLabel(interest);
    final base = '${_opener(store)}'
        '${me.nickname}さん、${store.nickname}（${store.storeType}）のAI接客です。';
    if (label == null) {
      return '$base ワンちゃんのことなら何でも聞いてください。';
    }
    return '$base $labelがお好みなんですね。'
        'うちの${_recommend(store)}がおすすめです。';
  }

  /// 店舗タイプごとの口調（本開発では LLM に店舗キャラ設定を渡して生成する）
  String _opener(BusinessUser store) {
    switch (store.storeType) {
      case 'ドッグラン':
        return 'いらっしゃい！うちの子と一緒に走り回りませんか。';
      case 'ドッグカフェ':
        return 'こんにちは。テラス席のご用意がありますよ。';
      case 'ペットサロン・トリミング':
        return 'いらっしゃいませ。ワンちゃんのペースに合わせて丁寧にトリミングします。';
      case '動物病院':
        return 'こんにちは。少し気になることも、気軽にご相談ください。';
      default:
        return 'いらっしゃいませ。';
    }
  }

  /// ユーザー発話への応答
  String reply(String input, AppUser me, BusinessUser store) {
    final text = input.replaceAll(RegExp(r'\s'), '');
    if (text.contains('予約') || text.contains('来店')) {
      return 'ありがとうございます。土日は混み合うため、'
          '平日の午前中でしたらゆっくりご案内できます。'
          'ご希望の時間をメモしておきますね。'
          '（デモのため実際の予約機能は本開発で提供します）';
    }
    if (text.contains('おすすめ') || text.contains('オススメ')) {
      return '今回は${_recommend(store)}がおすすめです。'
          'ワンちゃんの苦手なものがあれば教えてください。';
    }
    if (text.contains('犬種') || text.contains('大型犬') ||
        text.contains('小型犬')) {
      return '大型犬・小型犬どちらも歓迎しています。'
          '初めてのワンちゃんには慣れるまで短い時間からのご利用をおすすめしています。';
    }
    if (text.contains('料金') || text.contains('いくら') ||
        text.contains('価格')) {
      return 'ご利用内容によって変わりますが、まずは一度お試しいただけます。'
          '詳しいプランは店舗ページをご確認ください（デモの固定値です）。';
    }
    if (text.contains('何時') || text.contains('営業時間')) {
      return '本日は10:00〜18:00で営業しております。'
          '混雑しやすいのは土曜午前です。（デモの固定値です）';
    }
    if (text.contains('水') || text.contains('トイレ')) {
      return '飲水場と水洗トイレを備えています。'
          '足拭き用のタオルも貸し出していますので、ご利用ください。';
    }
    return '承知しました。「おすすめ」「料金」「営業時間」「予約」「大型犬」など、'
        '気になることを聞いていただければ答えます。';
  }

  String _recommend(BusinessUser store) {
    switch (store.storeType) {
      case 'ドッグラン':
        return '小型犬と大型犬が分かれた開放エリア';
      case 'ドッグカフェ':
        return '手作りドッグおやつセット';
      case 'ペットサロン・トリミング':
        return '初回のお試しシャンプーコース';
      case '動物病院':
        return 'ワンちゃんの健康診断プラン';
      default:
        return 'おすすめサービス';
    }
  }

  String _categoryLabel(String id) {
    const labels = {
      'sanpo': 'お散歩',
      'dogrun': 'ドッグラン',
      'dogcafe': 'ドッグカフェ',
      'training': 'しつけ・トレーニング',
      'sports': 'アジリティ・ドッグスポーツ',
      'photo': '愛犬撮影',
      'goods': 'グッズ・おやつ研究',
      'travel': 'お出かけ・旅行',
      'health': '健康・動物病院',
      'grooming': 'トリミング・お手入れ',
      'rescue': '保護犬・里亲身',
      'wanko': '犬友達・多頭飼い',
    };
    return labels[id] ?? '犬のこと';
  }
}

/// グローバルインスタンス（本開発では DI / LLM API クライアントに置き換える）
final AiConcierge aiConcierge = AiConcierge();

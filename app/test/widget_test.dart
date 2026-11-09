import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshitomo/main.dart';
import 'package:meshitomo/src/models.dart';
import 'package:meshitomo/src/services/ai_concierge.dart';
import 'package:meshitomo/src/services/app_state.dart';
import 'package:meshitomo/src/services/auth_service.dart';
import 'package:meshitomo/src/util/format.dart';
import 'package:meshitomo/src/util/share_text.dart';

AppUser _testUser(AppState state, {String id = 'me', String nickname = 'テスト太郎'}) {
  return AppUser(
    id: id,
    nickname: nickname,
    decade: '30代',
    gender: 'male',
    iconCategoryId: 'ramen',
    interestIds: const ['ramen'],
    bio: 'テスト',
    lat: state.anchorLat,
    lng: state.anchorLng,
  );
}

void main() {
  group('format utils', () {
    test('距離は粗いバンド表示になる（FR-2-2）', () {
      expect(distanceLabel(0.3), '〜1km');
      expect(distanceLabel(2.4), '1〜3km');
      expect(distanceLabel(4.9), '3〜5km');
      expect(distanceLabel(7.2), '5〜10km');
      expect(distanceLabel(23.0), '10km〜');
    });

    test('残り時間ラベル', () {
      final now = DateTime(2026, 2, 1, 12, 0);
      expect(remainingLabel(now.add(const Duration(minutes: 42)), now),
          '残り42分');
      expect(remainingLabel(now.add(const Duration(hours: 2)), now),
          '残り2時間');
      expect(
          remainingLabel(now.add(const Duration(hours: 1, minutes: 20)), now),
          '残り1時間20分');
      expect(remainingLabel(now.subtract(const Duration(minutes: 1)), now),
          '終了');
    });
  });

  group('share_text（SNS共有文）', () {
    test('招待文にニックネームとURLが入る', () {
      final t = inviteText('焼肉のみゆ');
      expect(t, contains('焼肉のみゆ'));
      expect(t, contains(kAppUrl));
      expect(t, contains('完全無料'));
    });

    test('募集の共有文にタイトルと集合場所が入る', () {
      final t = recruitmentShareText('今夜19時ラーメン', '神田駅');
      expect(t, contains('今夜19時ラーメン'));
      expect(t, contains('神田駅'));
      expect(t, contains(kAppUrl));
    });

    test('同業者向けの紹介文に店舗名と業態と無料表記が入る', () {
      final t = businessInviteText('居酒屋 のれん', '居酒屋');
      expect(t, contains('居酒屋 のれん'));
      expect(t, contains('居酒屋'));
      expect(t, contains('無料'));
      expect(t, contains(kAppUrl));
    });
  });

  group('AuthService（モック認証）', () {
    test('会員登録するとログイン状態になり、ログアウト・再ログインができる',
        () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthService();
      await auth.init();

      // 会員登録 → 同時にログインされる
      await auth.register(
        email: 'Test@Example.com',
        password: 'secret123',
        nickname: '太郎',
        decade: '30代',
        gender: 'male',
        iconCategoryId: 'ramen',
        interestIds: const ['ramen'],
        bio: 'テスト',
      );
      expect(auth.sessionEmail, 'test@example.com'); // 小文字化して保存
      expect(auth.sessionNickname(), '太郎');

      // ログアウト → セッション消えるがアカウントは残る
      await auth.logout();
      expect(auth.hasSession, isFalse);
      await auth.login('test@example.com', 'secret123');
      expect(auth.hasSession, isTrue);

      // 誤パスワードは拒否される
      await expectLater(
        auth.login('test@example.com', 'wrong-pw'),
        throwsA(isA<AuthException>()),
      );

      // 同 email の再登録は拒否される
      await expectLater(
        auth.register(
          email: 'test@example.com',
          password: 'x',
          nickname: '二郎',
          decade: '20代',
          gender: 'male',
          iconCategoryId: 'ramen',
          interestIds: const ['ramen'],
          bio: '',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('セッションからユーザーを復元できる', () async {
      SharedPreferences.setMockInitialValues({});
      final auth = AuthService();
      await auth.init();
      await auth.register(
        email: 'a@b.com',
        password: 'secret123',
        nickname: '花子',
        decade: '20代',
        gender: 'female',
        iconCategoryId: 'sweets',
        interestIds: const ['sweets'],
        bio: 'テスト',
      );
      final user = await auth.buildSessionUser(lat: 35.0, lng: 139.0);
      expect(user, isNotNull);
      expect(user!.nickname, '花子');
      expect(user.lat, 35.0);
    });
  });

  group('AiConcierge（AI接客デモ）', () {
    final me = AppUser(
      id: 'me',
      nickname: '太郎',
      decade: '30代',
      gender: 'male',
      iconCategoryId: 'ramen',
      interestIds: const ['ramen'],
      bio: 'テスト',
      lat: 35.0,
      lng: 139.0,
    );
    final store = BusinessUser(
      id: 'b-ramen-niban',
      nickname: 'ラーメン二番',
      decade: '経営者',
      gender: 'undisclosed',
      iconCategoryId: 'ramen',
      interestIds: const [],
      bio: 'デモ店舗',
      lat: 35.0,
      lng: 139.0,
      storeType: 'ラーメン店',
    );

    test('挨拶は店舗の口調とユーザーの興味を踏まえて案内する', () {
      final g = aiConcierge.greeting(me, store);
      expect(g, contains('ようこそ')); // ラーメン店の口調
      expect(g, contains('太郎'));
      expect(g, contains('ラーメン'));
      expect(g, contains('とんこつ背脂'));
    });

    test('口調は店舗タイプごとに変わる', () {
      final izakaya = BusinessUser(
        id: 'b-izakaya-noren',
        nickname: '居酒屋 のれん',
        decade: '経営者',
        gender: 'undisclosed',
        iconCategoryId: 'izakaya',
        interestIds: const [],
        bio: 'デモ店舗',
        lat: 35.0,
        lng: 139.0,
        storeType: '居酒屋',
      );
      expect(aiConcierge.greeting(me, izakaya), contains('お疲れさん'));
    });

    test('キーワードに応じた応答をする（おすすめ/席/予約/Business unknown）',
        () {
      final ai = aiConcierge;
      expect(ai.reply('おすすめは？', me, store), contains('とんこつ'));
      expect(ai.reply('席が空いてる？', me, store), contains('カウンター'));
      expect(ai.reply('予約したいです', me, store), contains('19時'));
      // どのキーワードにも当てはまらない場合は案内を返す
      expect(ai.reply('こんにちは', me, store), contains('おすすめ'));
    });
  });

  group('AppState（ドメイン状態）', () {
    test('ログインすると近くの募集・一般・ビジネスユーザーが見える', () {
      final state = AppState();
      expect(state.me, isNull);
      expect(state.activeRecruitments(), isEmpty);

      state.attachUser(_testUser(state), reseed: true);
      expect(state.me, isNotNull);
      expect(state.activeRecruitments(), isNotEmpty);
      expect(state.generalUsers, isNotEmpty);
      expect(state.businessUsers, isNotEmpty);
      // ビジネスユーザーは募集一覧の host には出てこない
      expect(
        state.activeRecruitments().every(
            (r) => state.userById(r.hostId).isBusiness == false),
        isTrue,
      );
    });

    test('GPS適用でモックが現在地周囲に再配置される', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      state.applyGps(43.0, 141.0);
      expect(state.gpsAvailable, isTrue);
      // 一般ユーザーは現在地（anchor）から粗いバンド内に並ぶ
      for (final u in state.generalUsers) {
        final km = haversineKm(state.anchorLat, state.anchorLng, u.lat, u.lng);
        expect(km, lessThan(6.0));
      }
    });

    test('募集を作ると期限付きで立ち一覧に載る', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final rec = await state.createRecruitment(
        genreId: 'meshi',
        title: 'テストの募集',
        body: '本文',
        meetup: 'テスト駅',
        capacity: 2,
        expiryHours: 2,
      );
      expect(rec.isActiveAt(DateTime.now()), isTrue);
      expect(state.activeRecruitments().map((r) => r.id), contains(rec.id));
      expect(state.recruitmentDistanceLabel(rec), 'あなたの募集');
    });

    test('他人の募集への応募は数秒後に承認され部屋ができる（デモ挙動）', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final target = state
          .activeRecruitments()
          .firstWhere((r) => r.hostId != state.me!.id);
      state.applyTo(target.id, message: 'よろしくお願いします');
      expect(state.myPendingApplication(target.id), isNotNull);
      await Future<void>.delayed(const Duration(seconds: 4));
      expect(state.myRooms, isNotEmpty);
      expect(state.messagesOf(state.myRooms.first.id), isNotEmpty);
    });

    test('存在しない応募の承認 / 却下は無視される', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      state.acceptApplication('nonexistent');
      state.declineApplication('nonexistent');
      expect(state.myRooms, isEmpty);
    });

    test('投稿アイコン画像は GPS・プロフィール更新でも保持される', () {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      state.updateProfile(
        nickname: 'テスト太郎',
        decade: '30代',
        gender: 'male',
        iconCategoryId: 'ramen',
        interestIds: const ['ramen'],
        bio: 'テスト',
        iconImagePath: '/data/user/0/app/icons/icon_1.jpg',
      );
      expect(state.me!.iconImagePath, isNotEmpty);
      state.applyGps(43.0, 141.0);
      expect(state.me!.iconImagePath, isNotEmpty);
    });

    test('DM: 同一相手との部屋は再利用され、違う相手は別の部屋になる', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final other = state.generalUsers.first;
      final dm1 = await state.getOrCreateDm(other.id);
      final dm2 = await state.getOrCreateDm(other.id);
      expect(dm1.id, dm2.id);
      final other2 = state.generalUsers[1];
      final dm3 = await state.getOrCreateDm(other2.id);
      expect(dm3.id, isNot(dm1.id));
      expect(state.myRooms.where((r) => r.isDm), hasLength(2));
      expect(state.lastMessageOf(dm1.id), isNotEmpty); // system メッセージ
    });

    test('リアルタイム着信は重複せず、他人のメッセージは未読が増える',
        () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final other = state.generalUsers.first;
      final room = await state.getOrCreateDm(other.id);
      final before = state.unreadByRoom[room.id] ?? 0;
      final msg = ChatMessage(
        id: 'incoming-1',
        roomId: room.id,
        senderId: other.id,
        body: 'こんにちは',
        sentAt: DateTime.now(),
      );
      state.handleIncomingMessage(room.id, msg);
      state.handleIncomingMessage(room.id, msg); // 重複着信
      expect(
          state.messagesOf(room.id)
              .where((m) => m.id == 'incoming-1'),
          hasLength(1));
      expect(state.unreadByRoom[room.id], before + 1);
    });

    test('コミュニティ: モックでは参加中シードがあり、参加すると部屋ができる',
        () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      expect(state.communities, isNotEmpty);
      final target =
          state.communities.firstWhere((c) => !c.memberIds.contains('me'));
      final before = state.myRooms.length;
      await state.joinCommunity(target.id);
      expect(state.myCommunities.map((c) => c.id), contains(target.id));
      expect(state.myRooms.length, before + 1);
      final room = state.myRooms
          .firstWhere((r) => r.communityId == target.id);
      expect(room.isCommunity, isTrue);
      // コミュニティチャットに投稿できる
      await state.sendCommunityMessage(target.id, 'こんにちは');
      expect(state.lastMessageOf(room.id), contains('こんにちは'));
    });

    test('コミュニティ作成とイベント企画（誰でも作成できる）', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      final created = await state.createCommunity(
        name: 'テスト同好会',
        description: 'テスト用',
        linkedStore: null,
      );
      expect(created.memberIds, contains('me'));
      // 作成者は自動で参加し、チャット部屋ができている
      expect(state.myRooms.where((r) => r.communityId == created.id),
          isNotEmpty);
      final event = await state.createEvent(
        communityId: created.id,
        title: 'テストオフ会',
        body: '',
        eventTime: '来週土曜',
        locationName: '駅前',
        capacity: 3,
      );
      final stored = state.eventsOf(created.id);
      expect(stored, hasLength(1));
      expect(stored.first.id, event.id);
      expect(stored.first.participantIds, contains('me')); // 主催は自動参加
    });

    test('イベントへの参加・取消ができる', () async {
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      // シード済みコミュニティ（自分未参加の c-ramen）のイベントへ参加する
      final community =
          state.communities.firstWhere((c) => c.id == 'c-ramen');
      final target = state.eventsOf(community.id).first;
      await state.joinEvent(target.id);
      expect(state.eventsOf(community.id).first.participantIds,
          contains('me'));
      await state.leaveEvent(target.id);
      expect(state.eventsOf(community.id).first.participantIds,
          isNot(contains('me')));
    });

    test('興味カテゴリをユーザーが自由に追加できる（重複名は拒否）', () async {
      SharedPreferences.setMockInitialValues({});
      final state = AppState();
      state.attachUser(_testUser(state), reseed: true);
      // attachUser 内で loadCategories が走る
      final before = state.categories.length;
      final created =
          await state.addCategory(label: '珈琲巡り', iconName: 'coffee');
      expect(created, isNotNull);
      expect(state.categories.length, before + 1);
      expect(state.categories.any((c) => c.label == '珈琲巡り'), isTrue);
      // 未知のIDはフォールバック表示（例外にならない）
      final unknown = state.categoryOf('made-on-other-device');
      expect(unknown.label, 'made-on-other-device');
      // 同名カテゴリは拒否される
      final dup =
          await state.addCategory(label: '珈琲巡り', iconName: 'restaurant');
      expect(dup, isNull);
      expect(state.categories.length, before + 1);
    });
  });

  group('models', () {
    test('Recruitment の期限切れ / 満員状態（FR-2-1）', () {
      final now = DateTime(2026, 2, 1, 12, 0);
      final rec = Recruitment(
        id: 'r-x',
        hostId: 'h',
        genreId: 'meshi',
        title: 't',
        body: 'b',
        meetup: 'm',
        capacity: 2,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
        memberIds: const ['h'],
      );
      expect(rec.isActiveAt(now), isTrue);
      expect(rec.statusAt(now), RecStatus.active);
      expect(rec.statusAt(now.add(const Duration(hours: 3))),
          RecStatus.expired);

      final full = Recruitment(
        id: rec.id,
        hostId: rec.hostId,
        genreId: rec.genreId,
        title: rec.title,
        body: rec.body,
        meetup: rec.meetup,
        capacity: rec.capacity,
        createdAt: rec.createdAt,
        expiresAt: rec.expiresAt,
        memberIds: const ['h', 'x'],
      );
      expect(full.isActiveAt(now), isFalse);
      expect(full.statusAt(now), RecStatus.fulfilled);
      expect(full.remainingSlots, 0);
    });
  });

  testWidgets('未ログインではログイン画面が出る', (tester) async {
    await tester.pumpWidget(const MeshitomoApp());
    expect(find.text('飯とも！'), findsOneWidget);
    expect(find.text('ログイン'), findsWidgets);
    expect(find.text('はじめての方は会員登録へ'), findsOneWidget);
    expect(find.text('会員登録'), findsNothing);

    // 会員登録へ遷移できる
    await tester.tap(find.text('はじめての方は会員登録へ'));
    await tester.pumpAndSettle();
    expect(find.text('会員登録'), findsWidgets);
    // 同意前は先へ進めない（FR-1-4, 1.2）
    final next = find
        .ancestor(of: find.text('プロフィール入力へ'),
            matching: find.byType(FilledButton))
        .first;
    expect(tester.widget<FilledButton>(next).enabled, isFalse);
  });
}

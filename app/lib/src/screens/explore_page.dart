import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/format.dart';
import 'community_detail_screen.dart';
import 'protected_dogs_page.dart';
import 'store_sheet.dart';
import 'user_detail_screen.dart';
import 'widgets.dart';

/// 「探す」タブ: カテゴリで近くの人を探し、店舗・コミュニティも探せる
/// （FR-2-3, FR-2-4, FR-5-3, FR-6-1〜6-3）。
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? _selectedCategory;
  final TextEditingController _storeSearch = TextEditingController();

  @override
  void dispose() {
    _storeSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final users = appState.generalUsers
                .where((u) => _selectedCategory == null
                    ? true
                    : u.interestIds.contains(_selectedCategory))
                .toList()
              ..sort((a, b) {
                final da = _distanceKm(a);
                final db = _distanceKm(b);
                return da.compareTo(db);
              });
            final stores = appState.businessUsers
              ..sort((a, b) => _distanceKm(a).compareTo(_distanceKm(b)));
            final storeKeyword = _storeSearch.text.trim().toLowerCase();
            final filteredStores = storeKeyword.isEmpty
                ? stores
                : stores
                    .where((s) =>
                        s.nickname.toLowerCase().contains(storeKeyword) ||
                        s.storeType.toLowerCase().contains(storeKeyword) ||
                        s.bio.toLowerCase().contains(storeKeyword))
                    .toList();
            final communities = appState.nearbyCommunities;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('カテゴリ', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('すべて'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                    for (final c in appState.categories)
                      FilterChip(
                        avatar: Icon(c.icon, size: 18),
                        label: Text(c.label),
                        selected: _selectedCategory == c.id,
                        onSelected: (v) => setState(() =>
                            _selectedCategory = v ? c.id : null),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('近くの犬とも候補（${users.length}人）',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final u in users)
                  Card(
                    child: ListTile(
                      leading: userAvatar(u.id, size: 44),
                      title: Text(u.nickname,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${u.decade} / ${u.genderLabel} / ${distanceLabel(_distanceKm(u))}',
                      ),
                      trailing: Wrap(
                        spacing: 4,
                        children: [
                          for (final id in u.interestIds.take(2))
                            Icon(appState.categoryOf(id).icon,
                                size: 18, color: Colors.grey.shade600),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => UserDetailScreen(userId: u.id),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // ------------------------------------------- 店を探す
                Row(
                  children: [
                    Icon(Icons.storefront,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('ドッグランやサロンを探す',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(width: 8),
                    Text('（${filteredStores.length}件）',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _storeSearch,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: '店名・業態で検索',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    suffixIcon: storeKeyword.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _storeSearch.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                if (filteredStores.isEmpty)
                  Text(
                    '近くに登録された店舗はまだありません。'
                    'ビジネスユーザーとして登録すると、ここにお店を出せます。',
                    style: theme.textTheme.bodySmall,
                  ),
                for (final s in filteredStores)
                  Card(
                    child: ListTile(
                      leading: userAvatar(s.id, size: 44),
                      title: Text(s.nickname,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${s.storeType} / ${distanceLabel(_distanceKm(s))}'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: Colors.brown.shade200),
                        ),
                        child: Text(
                          'お店',
                          style: TextStyle(
                              fontSize: 11, color: Colors.brown.shade800),
                        ),
                      ),
                      onTap: () => showStoreSheet(context, s),
                    ),
                  ),
                const SizedBox(height: 24),

                // -------------------------------------- 保護犬・迷子犬
                Card(
                  color:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.pets,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('保護犬・迷子犬',
                                style: theme.textTheme.titleSmall),
                            const SizedBox(width: 8),
                            Text('（${appState.protectedDogs.length}件）',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '見つけて保護したワンちゃん・いなくなったワンちゃんの情報を'
                          '近くで共有します。近くの登録を近い順に探せて、'
                          '登録者に直接連絡することもできます。',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('探す・登録する'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProtectedDogsPage(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -------------------------------- コミュニティ・イベント
                Row(
                  children: [
                    Icon(Icons.groups,
                        size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('近くのコミュニティ・イベント',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(width: 8),
                    Text('（${communities.length}）',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '犬種オフ会・ドッグラン常連会・撮影会など。'
                  '誰でも作成・参加でき、参加するとチャットが始まります。',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                if (communities.isEmpty)
                  Text(
                    'まだコミュニティがありません。「コミュニティ」タブの「作る」から始められます。',
                    style: theme.textTheme.bodySmall,
                  ),
                for (final c in communities)
                  Card(
                    child: ListTile(
                      leading: userAvatar(c.ownerId, size: 44),
                      title: Text(
                        c.linkedStore != null
                            ? '${c.name}（${c.linkedStore}のファン）'
                            : c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${c.memberIds.length}人参加 / ${appState.communityDistanceLabel(c)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: appState.me!.id == c.ownerId ||
                              c.memberIds.contains(appState.me!.id)
                          ? const Icon(Icons.chat_bubble_outline)
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.brown.shade200),
                              ),
                              child: Text(
                                '参加',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.brown.shade800),
                              ),
                            ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              CommunityDetailScreen(communityId: c.id),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  double _distanceKm(AppUser u) {
    final me = appState.me!;
    return haversineKm(me.lat, me.lng, u.lat, u.lng);
  }
}

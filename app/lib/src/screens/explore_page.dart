import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/format.dart';
import 'community_detail_screen.dart';
import 'store_sheet.dart';
import 'user_detail_screen.dart';
import 'widgets.dart';

/// 「探す」タブ: 上部のボタンで「犬とも候補 / ビジネスユーザー /
/// コミュニティ・イベント」を素早く切り替えて探す（FR-2-3, FR-5-3, FR-6-1〜6-4）。
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

enum ExploreSection { people, business, community }

class _ExplorePageState extends State<ExplorePage> {
  ExploreSection _section = ExploreSection.people;
  String? _selectedCategory;
  final TextEditingController _storeSearch = TextEditingController();

  @override
  void dispose() {
    _storeSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SegmentedButton<ExploreSection>(
                segments: const [
                  ButtonSegment(
                    value: ExploreSection.people,
                    icon: Icon(Icons.person_search_outlined),
                    label: Text('犬とも候補'),
                  ),
                  ButtonSegment(
                    value: ExploreSection.business,
                    icon: Icon(Icons.storefront_outlined),
                    label: Text('ビジネス'),
                  ),
                  ButtonSegment(
                    value: ExploreSection.community,
                    icon: Icon(Icons.groups_outlined),
                    label: Text('コミュニティ'),
                  ),
                ],
                selected: {_section},
                onSelectionChanged: (s) => setState(() => _section = s.first),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  switch (_section) {
                    case ExploreSection.people:
                      return _peopleList(context);
                    case ExploreSection.business:
                      return _businessList(context);
                    case ExploreSection.community:
                      return _communityList(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------ 犬とも候補探す

  Widget _peopleList(BuildContext context) {
    final theme = Theme.of(context);
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('犬とも候補探す', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Text('興味カテゴリ', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              label: const Text('すべて'),
              selected: _selectedCategory == null,
              onSelected: (_) => setState(() => _selectedCategory = null),
            ),
            for (final c in appState.categories)
              FilterChip(
                avatar: Icon(c.icon, size: 18),
                label: Text(c.label),
                selected: _selectedCategory == c.id,
                onSelected: (v) =>
                    setState(() => _selectedCategory = v ? c.id : null),
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
      ],
    );
  }

  // ------------------------------------------ ビジネスユーザーを探す

  Widget _businessList(BuildContext context) {
    final theme = Theme.of(context);
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('ビジネスユーザーを探す', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'ドッグラン、ドッグカフェ、ペットサロン、動物病院などの店舗',
          style: theme.textTheme.bodySmall,
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
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle:
                  Text('${s.storeType} / ${distanceLabel(_distanceKm(s))}'),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.brown.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.brown.shade200),
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
      ],
    );
  }

  // ------------------------------------ 近くのコミュニティ・イベント探す

  Widget _communityList(BuildContext context) {
    final theme = Theme.of(context);
    final communities = appState.nearbyCommunities;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('近くのコミュニティ・イベント探す',
            style: theme.textTheme.titleSmall),
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
              trailing:
                  appState.me!.id == c.ownerId || c.memberIds.contains(appState.me!.id)
                      ? const Icon(Icons.chat_bubble_outline)
                      : Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.brown.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border:
                                Border.all(color: Colors.brown.shade200),
                          ),
                          child: Text(
                            '参加',
                            style: TextStyle(
                                fontSize: 11, color: Colors.brown.shade800),
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
  }

  double _distanceKm(AppUser u) {
    final me = appState.me!;
    return haversineKm(me.lat, me.lng, u.lat, u.lng);
  }
}

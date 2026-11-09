import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/format.dart';
import 'widgets.dart';

/// 「探す」タブ: カテゴリで近くの人を探す（FR-2-4）。
/// コミュニティ・店舗・クーポンは v1.5/v2 で追加される位置のプレビューを表示。
class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  String? _selectedCategory;

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
                Text('近くの飯とも候補（${users.length}人）',
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
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storefront,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('店を探す（v1.5で追加）',
                                style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ビジネスユーザー（飲食店）が店舗を登録し、'
                          '地図連携（マップ表示・Googleマップで開く）や'
                          'お店へのDM・電話連絡をご利用いただけます。'
                          'ベータ期間中は無料です（AI接客は準備中）。',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.groups,
                                color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text('コミュニティ・イベント（v2で追加）',
                                style: theme.textTheme.titleSmall),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '常連の居酒屋コミュニティ、社会人部活、地域のイベントなど、'
                          '誰でも作成・参加できるようになります。'
                          'ビジネスユーザーも一般ユーザーも一緒に参加できます。',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
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

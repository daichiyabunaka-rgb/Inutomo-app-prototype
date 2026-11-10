import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/format.dart';
import 'chat_screen.dart';
import 'protected_dog_create_sheet.dart';
import 'user_detail_screen.dart';
import 'widgets.dart';

/// 「保護犬・迷子犬」タブ: 見つけて保護したワンちゃん・いなくなったワンちゃんの
/// 情報を近隣で共有する（FR-7-1〜7-4）。
/// 譲渡・里親探しは本アプリでは行わず、自治体・保護団体の正式な手続きへ誘導する。
class ProtectedDogsPage extends StatefulWidget {
  const ProtectedDogsPage({super.key});

  @override
  State<ProtectedDogsPage> createState() => _ProtectedDogsPageState();
}

class _ProtectedDogsPageState extends State<ProtectedDogsPage> {
  String _filter = 'all'; // 'all' | 'protected' | 'lost'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showProtectedDogCreateSheet(context),
        icon: const Icon(Icons.pets),
        label: const Text('登録する'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final all = appState.protectedDogs;
            final dogs = _filter == 'all'
                ? all
                : all
                      .where(
                        (p) =>
                            _filter == 'protected' ? p.isProtected : p.isLost,
                      )
                      .toList();
            return RefreshIndicator(
              onRefresh: () => appState.refreshFromRemote(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '保護犬・迷子犬',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('すべて')),
                      ButtonSegment(value: 'protected', label: Text('保護')),
                      ButtonSegment(value: 'lost', label: Text('迷子')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '近くで登録された情報を近い順に表示します。'
                    '見つけたワンちゃん・いなくなったワンちゃんの情報を登録して、'
                    '飼い主さんとの再会につなげましょう。',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '※保護したワンちゃんは、お住まいの自治体（保健所等）への'
                    '届け出が動物愛護法で義務付けられています。'
                    '譲渡・里親探しは、自治体や保護団体の正式な手続で行ってください。',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (dogs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '近くに登録はまだありません。\n'
                          '「登録する」から最初の登録をお願いします。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  for (final d in dogs) _dogCard(context, d),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dogCard(BuildContext context, ProtectedDog d) {
    final theme = Theme.of(context);
    final reporter = appState.userById(d.reporterId);
    final isMine = d.reporterId == appState.me!.id;
    final now = DateTime.now();
    final protectedColor = Colors.teal.shade700;
    final lostColor = Colors.red.shade700;
    final color = d.isProtected ? protectedColor : lostColor;
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: d.isProtected
                        ? Colors.teal.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: d.isProtected
                          ? Colors.teal.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Text(
                    d.isProtected ? '保護' : '迷子',
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.dogDescription,
                    style: theme.textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.place, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    d.areaName,
                    style: TextStyle(color: Colors.grey.shade700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 2),
                Text(
                  '${elapsedLabel(d.createdAt, now)}の登録 / '
                  '${appState.protectedDogDistanceLabel(d)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_hasPhoto(d))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: GestureDetector(
                    onTap: () => _showPhoto(context, d),
                    child: _photoImage(d, 320),
                  ),
                ),
              ),
            if (d.detail.isNotEmpty)
              Text(d.detail, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => UserDetailScreen(userId: reporter.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      userAvatar(reporter.id, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        reporter.nickname,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isMine)
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('解決済みにする'),
                    onPressed: () => _confirmResolve(context, d),
                  )
                else
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('この人にDM', style: TextStyle(fontSize: 13)),
                    onPressed: () async {
                      final room = await appState.getOrCreateDm(reporter.id);
                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ChatScreen(roomId: room.id),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _hasPhoto(ProtectedDog d) {
    final p = d.photoPath ?? '';
    if (p.isEmpty) return false;
    if (p.startsWith('http')) return true;
    return File(p).existsSync();
  }

  Widget _photoImage(ProtectedDog d, double height) {
    final p = d.photoPath!;
    final Widget image;
    if (p.startsWith('http')) {
      image = Image.network(p,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    } else {
      image = Image.file(File(p),
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink());
    }
    return image;
  }

  /// 写真を全画面で見る
  void _showPhoto(BuildContext context, ProtectedDog d) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: _photoImage(d, 480),
        ),
      ),
    );
  }

  Future<void> _confirmResolve(BuildContext context, ProtectedDog d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('解決済みにしますか？'),
        content: const Text(
          '飼い主さんと再会した、保護先へ引き取られた等、解決した場合に'
          '設定します。解決済みの登録は一覧から表示されなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('解決済みにする'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await appState.resolveProtectedDog(d.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('解決済みにしました。一覧から削除されます'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

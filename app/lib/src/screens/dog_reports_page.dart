import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/format.dart';
import 'chat_screen.dart';
import 'dog_report_create_sheet.dart';
import 'user_detail_screen.dart';
import 'widgets.dart';

/// 「近況報告」タブ: 愛犬の近況・撮影・イベントの報告を近隣で共有する
/// （FR-7-1〜7-4 相当）。
/// kind: 'shoot'（撮影）/ 'post'（つぶやき）/ 'event'（イベント）。
/// 他人が写る画像は許諾を確認できたもののみ投稿する。
class DogReportsPage extends StatefulWidget {
  const DogReportsPage({super.key});

  @override
  State<DogReportsPage> createState() => _DogReportsPageState();
}

class _DogReportsPageState extends State<DogReportsPage> {
  String _filter = 'all'; // 'all' | 'shoot' | 'post' | 'event'

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showDogReportCreateSheet(context),
        icon: const Icon(Icons.photo_camera),
        label: const Text('報告する'),
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final all = appState.dogReports;
            final items = _filter == 'all'
                ? all
                : all.where((p) => p.kind == _filter).toList();
            return RefreshIndicator(
              onRefresh: () => appState.refreshFromRemote(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '近況報告',
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'all', label: Text('すべて')),
                      ButtonSegment(value: 'shoot', label: Text('撮影')),
                      ButtonSegment(value: 'post', label: Text('つぶやき')),
                      ButtonSegment(value: 'event', label: Text('イベント')),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (s) =>
                        setState(() => _filter = s.first),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '近くの犬仲間の近況・愛犬やドッグランの撮影・オフ会の'
                    '報告を近い順に表示します。報告を見て、'
                    '同じ趣味の仲間とつながりましょう。',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '※他人が写る画像は許諾を得たものだけ投稿してください。'
                    'パークやドッグランは各施設のルールを守って利用してください。'
                    '違反は削除・通報の対象になります。',
                    style: theme.textTheme.labelSmall!.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          '近くに報告はまだありません。\n'
                          '「報告する」から最初の近況報告をお願いします。',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  for (final d in items) _reportCard(context, d),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _reportCard(BuildContext context, DogReport d) {
    final theme = Theme.of(context);
    final poster = appState.userById(d.posterId);
    final isMine = d.posterId == appState.me!.id;
    final now = DateTime.now();
    final shootColor = Colors.teal.shade700;
    final postColor = Colors.blue.shade700;
    final eventColor = Colors.deepPurple.shade700;
    final color = d.isShoot
        ? shootColor
        : (d.isPost ? postColor : eventColor);
    final bg = d.isShoot
        ? Colors.teal.shade50
        : (d.isPost ? Colors.blue.shade50 : Colors.deepPurple.shade50);
    final border = d.isShoot
        ? Colors.teal.shade200
        : (d.isPost ? Colors.blue.shade200 : Colors.deepPurple.shade200);
    final label = d.isShoot
        ? '撮影'
        : (d.isPost ? 'つぶやき' : 'イベント');
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
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.itemDescription,
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
                  '${elapsedLabel(d.createdAt, now)}の報告 / '
                  '${appState.dogReportDistanceLabel(d)}',
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
                      builder: (_) => UserDetailScreen(userId: poster.id),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  child: Row(
                    children: [
                      userAvatar(poster.id, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        poster.nickname,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (isMine)
                  TextButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('完了にする'),
                    onPressed: () => _confirmClose(context, d),
                  )
                else
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('この人にDM', style: TextStyle(fontSize: 13)),
                    onPressed: () async {
                      final room = await appState.getOrCreateDm(poster.id);
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

  bool _hasPhoto(DogReport d) {
    final p = d.photoPath ?? '';
    if (p.isEmpty) return false;
    if (p.startsWith('http')) return true;
    return File(p).existsSync();
  }

  Widget _photoImage(DogReport d, double height) {
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
  void _showPhoto(BuildContext context, DogReport d) {
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

  Future<void> _confirmClose(BuildContext context, DogReport d) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('完了にしますか？'),
        content: const Text(
          '報告を一覧から外す場合に設定します。'
          '完了にした報告は一覧から表示されなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('完了にする'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await appState.closeDogReport(d.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('完了にしました。一覧から削除されます'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/app_state.dart';
import 'chat_screen.dart';
import 'widgets.dart';

/// ユーザー詳細（プロフィール閲覧 + DM の起点）。
/// 出会い系ではなく飯とも候補として見る画面なので、募集や嗜好を主に表示する。
/// SNS・URLは本人がプロフィールで公開したものだけ表示する。
class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url),
          mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _call(String phone) async {
    try {
      await launchUrl(Uri.parse('tel:$phone'));
    } catch (_) {}
  }

  String _normalizedUrl(String raw) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    return 'https://$raw';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = appState.userById(userId);
    final isMe = appState.me!.id == user.id;
    final recruitments = appState
        .activeRecruitments()
        .where((r) => r.hostId == user.id)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  userAvatar(user.id, size: 88, iconScale: 0.45),
                  const SizedBox(height: 12),
                  Text(
                    user.nickname,
                    style: theme.textTheme.headlineSmall!
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user.isBusiness
                        ? '${(user as BusinessUser).storeType} / '
                            '${appState.userDistanceLabel(user)}'
                        : '${user.decade} / ${user.genderLabel} / '
                            '${appState.userDistanceLabel(user)}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final id in user.interestIds)
                        interestLabel(appState.categoryOf(id)),
                    ],
                  ),
                  if (user.snsNote?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.alternate_email,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            user.snsNote!,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (user.websiteUrl?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _open(_normalizedUrl(user.websiteUrl!)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              user.websiteUrl!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (user.isBusiness &&
                      (user.phone?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _call(user.phone!),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.phone,
                                size: 16, color: theme.colorScheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              user.phone!,
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (user.bio.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      user.bio,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!isMe) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('DMを始める'),
                onPressed: () async {
                  final room = await appState.getOrCreateDm(user.id);
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ChatScreen(roomId: room.id),
                    ),
                  );
                },
              ),
            ),
          ],
          if (recruitments.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('この人の募集', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final r in recruitments)
              Card(
                child: ListTile(
                  leading: genreChip(r.genreId),
                  title: Text(r.title, maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: Text(appState.recruitmentDistanceLabel(r)),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

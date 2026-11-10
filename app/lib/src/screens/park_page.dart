import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models.dart';
import '../services/app_state.dart';
import '../util/dog_parks.dart';
import '../util/format.dart';
import 'recruitment_create_sheet.dart';

/// 「近くの公園・ドッグラン」タブ（犬とも！の特別機能）。
/// 現在地の近くの公園・ドッグランを近い順に表示する。
/// 有料のドッグランは表示しない。各公園はGoogleマップで開けるほか、
/// その公園に直接募集（お散歩・ドッグラン）をかけることができる。
class ParkPage extends StatefulWidget {
  const ParkPage({super.key});

  @override
  State<ParkPage> createState() => _ParkPageState();
}

class _ParkPageState extends State<ParkPage> {
  String? _anchorKey;
  late Future<List<DogPark>> _future;

  void _reloadIfNeeded() {
    final key =
        '${appState.anchorLat.toStringAsFixed(5)},${appState.anchorLng.toStringAsFixed(5)}';
    if (key == _anchorKey) return;
    _anchorKey = key;
    _future = fetchDogParksNear(appState.anchorLat, appState.anchorLng);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        _reloadIfNeeded();
        return RefreshIndicator(
          onRefresh: () async {
            final f = fetchDogParksNear(appState.anchorLat, appState.anchorLng);
            setState(() {
              _anchorKey =
                  '${appState.anchorLat.toStringAsFixed(5)},${appState.anchorLng.toStringAsFixed(5)}';
              _future = f;
            });
            await f;
          },
          child: FutureBuilder<List<DogPark>>(
            key: ValueKey(_anchorKey),
            future: _future,
            builder: (context, snapshot) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 4),
                  Text(
                    '現在地の近くの公園・ドッグランを近い順に表示します。',
                    style: theme.textTheme.bodySmall,
                  ),
                  if (snapshot.connectionState != ConnectionState.done &&
                      !snapshot.hasError)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (snapshot.hasError) _errorCard(theme),
                  if (snapshot.hasData) ...[
                    if (snapshot.data!.isEmpty) _emptyCard(theme),
                    for (final p in snapshot.data!) _parkCard(context, p),
                  ],
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _errorCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.cloud_off, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('公園情報を取得できませんでした。通信状況をご確認ください。',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('再読み込み'),
            onPressed: () => setState(() => _anchorKey = null),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Icon(Icons.park, size: 40, color: Colors.grey.shade500),
          const SizedBox(height: 8),
          Text('近くに公園・ドッグランが見つかりませんでした。',
              style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _parkCard(BuildContext context, DogPark p) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  p.isDogRun ? Icons.pets : Icons.park,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: theme.textTheme.titleMedium!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${p.isDogRun ? 'ドッグラン' : '公園'} / '
                        '${distanceLabel(p.distanceKm)}',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (p.openingHours != null) ...[
              const SizedBox(height: 6),
              Text('時間: ${p.openingHours!}',
                  style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (p.isDogRun && p.feeFreeKnown) _chip(theme, '無料'),
                if (p.dogRule == 'yes') _chip(theme, '犬OK'),
                if (p.dogRule == 'leashed') _chip(theme, 'リード着用'),
                if (!p.isDogRun && p.dogRule == 'unknown')
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '犬の同伴可否は各公園のルールをご確認ください',
                      style: theme.textTheme.labelSmall!
                          .copyWith(color: Colors.grey.shade600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label:
                        const Text('Googleマップで開く', style: TextStyle(fontSize: 13)),
                    onPressed: () => _openGoogleMaps(p),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.campaign, size: 18),
                    label: const Text('この公園で募集',
                        style: TextStyle(fontSize: 13)),
                    onPressed: () =>
                        showRecruitmentCreateSheet(context, initialMeetup: p.name),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(ThemeData theme, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }

  Future<void> _openGoogleMaps(DogPark park) async {
    try {
      await launchUrl(Uri.parse(googleMapsUrlForPark(park)),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      // Googleマップアプリが無い環境では無視
    }
  }
}

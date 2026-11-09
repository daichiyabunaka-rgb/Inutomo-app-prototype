import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_state.dart';
import '../util/dog_parks.dart';
import '../util/format.dart';
import 'recruitment_create_sheet.dart';

/// 「近くの公園・ドッグラン」タブ（犬とも！の特別機能）。
/// 現在地の近くの犬OK公園・ドッグランを探して、
/// Googleマップで開く / その公園で散歩・ドッグランの募集をかける、ができる。
/// プロトタイプでは端末内のシードデータ。本開発では
/// Google Places API（dog_park / park）等で実データを取得する。
class ParkPage extends StatelessWidget {
  const ParkPage({super.key});

  Future<void> _openGoogleMaps(String name) async {
    final url = Uri.parse(googleMapsUrlForPark(name));
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Googleマップアプリが無い環境では無視
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final me = appState.me!;
    final parks = placeDogParks(appState.anchorLat, appState.anchorLng)
      ..sort((a, b) => _km(a).compareTo(_km(b)));

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const SizedBox(height: 4),
        Text(
          'ワンちゃんと一緒に行ける公園・ドッグランが近くで見つかります。'
          'Googleマップで開いて経路を確認できます（APIキー不要）。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final p in parks)
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        p.park.isDogRun ? Icons.pets : Icons.park,
                        color: theme.colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.park.name,
                              style: theme.textTheme.titleMedium!
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${p.park.isDogRun ? 'ドッグラン' : '犬OKの公園'} / '
                              '${distanceLabel(_km(p))}',
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
                  const SizedBox(height: 8),
                  Text(p.park.description,
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final f in p.park.features)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(f,
                              style: theme.textTheme.labelSmall),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: const Text('Googleマップで開く',
                              style: TextStyle(fontSize: 13)),
                          onPressed: () => _openGoogleMaps(p.park.name),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.campaign, size: 18),
                          label: const Text('この公園で募集',
                              style: TextStyle(fontSize: 13)),
                          onPressed: () => showRecruitmentCreateSheet(
                            context,
                            initialMeetup: p.park.name,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        if (me.isBusiness)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'ドッグラン・ドッグカフェなどを経営するビジネスユーザーは、'
              '「店」タブから登録すると地図にも表示されます。',
              style: theme.textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  double _km(PlacedPark p) {
    final me = appState.me!;
    return haversineKm(me.lat, me.lng, p.lat, p.lng);
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/app_state.dart';
import '../services/icon_service.dart';

/// 近況報告の登録シート（FR-7-1相当）。
/// kind: 'shoot'（撮影）/ 'post'（つぶやき）/ 'event'（イベント）
Future<void> showDogReportCreateSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CreateSheet(),
  );
}

class _CreateSheet extends StatefulWidget {
  const _CreateSheet();

  @override
  State<_CreateSheet> createState() => _CreateSheetState();
}

class _CreateSheetState extends State<_CreateSheet> {
  final _itemDescription = TextEditingController();
  final _areaName = TextEditingController();
  final _detail = TextEditingController();
  String _kind = 'shoot';
  String? _photoPath; // 選択した報告写真（null=未選択, ''=解除）
  bool _submitting = false;

  @override
  void dispose() {
    _itemDescription.dispose();
    _areaName.dispose();
    _detail.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final path = await iconService.pickDogReportPhoto(source);
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await appState.registerDogReport(
        kind: _kind,
        itemDescription: _itemDescription.text.trim(),
        areaName: _areaName.text.trim(),
        detail: _detail.text.trim(),
        photoPath:
            (_photoPath == null || _photoPath!.isEmpty) ? null : _photoPath,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('報告に失敗しました。通信状況を確認してください'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('報告しました。近くのユーザーに表示されます'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('近況報告を投稿する',
                style: theme.textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'shoot',
                  icon: Icon(Icons.photo_camera),
                  label: Text('撮影'),
                ),
                ButtonSegment(
                  value: 'post',
                  icon: Icon(Icons.chat_bubble_outline),
                  label: Text('つぶやき'),
                ),
                ButtonSegment(
                  value: 'event',
                  icon: Icon(Icons.celebration),
                  label: Text('イベント'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _kind == 'shoot'
                  ? '愛犬・ドッグラン・お散歩の写真の報告です。\n'
                      '※他人が写る画像は許諾を得たものだけ投稿してください。'
                  : _kind == 'post'
                      ? '近況・ひとことのつぶやきです。\n'
                          '※次のドッグランの予定や愛犬の近況など、犬仲間に伝えたいことを報告しましょう。'
                      : 'オフ会・ドッグランイベント・犬仲間の集まりの報告です。\n'
                          '※主催者・参加者のルールと許諾を守ってください。',
              style: theme.textTheme.labelSmall!
                  .copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _itemDescription,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'タイトル（愛犬・できごとなど）',
                hintText: '例: わんぱく公園でお散歩を楽しみました',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),

            // ------------------------------ 報告写真（任意）
            Text('写真（任意。報告の画像を）',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _photoPreview(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined,
                            size: 18),
                        label: const Text('ギャラリーから',
                            style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon:
                            const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('カメラで撮影',
                            style: TextStyle(fontSize: 13)),
                      ),
                      if (_photoPath != null && _photoPath!.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _photoPath = ''),
                          child: const Text('写真をはずす',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaName,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: '場所',
                hintText: '例: ○○ドッグラン / ○○公園',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detail,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '近況・ハイライトなど',
                hintText: '例: 初めてのアジリティに挑戦しました。今度一緒にどうですか',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_isValid && !_submitting) ? _submit : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('報告する'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isValid =>
      _itemDescription.text.trim().isNotEmpty &&
      _areaName.text.trim().isNotEmpty;

  Widget _photoPreview(ThemeData theme) {
    final path = (_photoPath ?? '');
    Widget preview;
    if (path.startsWith('http')) {
      preview = Image.network(path, width: 96, height: 96,
          fit: BoxFit.cover, errorBuilder: (_, _, _) => _emptyPreview());
    } else if (path.isNotEmpty && File(path).existsSync()) {
      preview =
          Image.file(File(path), width: 96, height: 96, fit: BoxFit.cover);
    } else {
      preview = _emptyPreview();
    }
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: preview,
      ),
    );
  }

  Widget _emptyPreview() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 32, color: Colors.grey),
      ),
    );
  }
}

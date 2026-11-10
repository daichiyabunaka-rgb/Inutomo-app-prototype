import 'package:flutter/material.dart';

import '../services/app_state.dart';

/// 保護犬・迷子犬の登録シート（FR-7-1）。
/// kind: 'protected'（見つけて保護した）/ 'lost'（手元からいなくなった）
Future<void> showProtectedDogCreateSheet(BuildContext context) {
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
  final _dogDescription = TextEditingController();
  final _areaName = TextEditingController();
  final _detail = TextEditingController();
  String _kind = 'protected';
  bool _submitting = false;

  @override
  void dispose() {
    _dogDescription.dispose();
    _areaName.dispose();
    _detail.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _dogDescription.text.trim().isNotEmpty &&
      _areaName.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      await appState.registerProtectedDog(
        kind: _kind,
        dogDescription: _dogDescription.text.trim(),
        areaName: _areaName.text.trim(),
        detail: _detail.text.trim(),
      );
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登録に失敗しました。通信状況を確認してください'),
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
        content: Text('登録しました。近くのユーザーに表示されます'),
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
            Text('保護犬・迷子犬を登録する',
                style: theme.textTheme.titleLarge!
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'protected',
                  icon: Icon(Icons.pets),
                  label: Text('保護した'),
                ),
                ButtonSegment(
                  value: 'lost',
                  icon: Icon(Icons.search),
                  label: Text('迷子になった'),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 4),
            Text(
              _kind == 'protected'
                  ? '見つけたワンちゃんを保護した場合: 飼い主さんを探している情報として共有されます。\n'
                      '※保護したワンちゃんは自治体（保健所等）への届け出が法律で義務です。'
                      '譲渡・里親探しは本アプリでは行いません。'
                  : '手元からワンちゃんがいなくなった場合: 目撃情報を集めるための情報として共有されます。\n'
                      '※マイクロチップ・鑑札の番号は載せず、個人が特定できる情報は記入しないでください。',
              style: theme.textTheme.labelSmall!
                  .copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dogDescription,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'ワンちゃんの特徴',
                hintText: '例: 柴犬（成犬・中型・茶色・首輪なし）',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _areaName,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: _kind == 'protected' ? '保護した場所' : '最後に見た場所',
                hintText: '例: 中央公園の駐車場周辺',
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detail,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: '状況・連絡方法など',
                hintText: '例: 現在自宅ゲート内で保護しています。お心当たりのある方はDMをください',
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
                  child: Text('登録する'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

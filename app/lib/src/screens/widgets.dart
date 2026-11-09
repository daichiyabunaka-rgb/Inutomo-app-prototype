import 'dart:io';

import 'package:flutter/material.dart';

import '../models.dart';
import '../services/app_state.dart';

/// 趣味アイコンのアバター。
/// 投稿画像（料理写真など）があればそれを表示し、なければ趣味アイコンセットに
/// フォールバックする。投稿画像は端末内パス（モック）または
/// Supabase Storage の公開URL（URLは network 経由で表示）。
/// 顔画像は不可（FR-1-3、AI審査は本開発で実装）。
Widget userAvatar(String userId, {double size = 44, double iconScale = 0.5}) {
  final user = appState.userById(userId);
  final imagePath = user.iconImagePath;
  if (imagePath != null && imagePath.isNotEmpty) {
    if (imagePath.startsWith('http')) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                _fallbackIcon(user, size, iconScale),
          ),
        ),
      );
    }
    final file = File(imagePath);
    if (file.existsSync()) {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackIcon(user, size, iconScale),
          ),
        ),
      );
    }
  }
  return _fallbackIcon(user, size, iconScale);
}

Widget _fallbackIcon(AppUser user, double size, double iconScale) {
  final cat = appState.categoryOf(user.iconCategoryId);
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.deepOrange.shade50,
    ),
    child: Icon(
      cat.icon,
      size: size * iconScale,
      color: Colors.deepOrange.shade800,
    ),
  );
}

Widget genreChip(String genreId) {
  final g = genreById(genreId);
  return Container(
    padding: const.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange.shade50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.shade200),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(g.icon, size: 14, color: Colors.orange.shade800),
        const SizedBox(width: 4),
        Text(g.label, style: TextStyle(color: Colors.orange.shade900, fontSize: 12)),
      ],
    ),
  );
}

Widget interestLabel(InterestCategory c) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(c.icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(c.label, style: TextStyle(color: Colors.grey.shade800, fontSize: 12)),
      ],
    ),
  );
}

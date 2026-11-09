import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// アイコン画像の取得と保存。
/// - モックモード: ギャラリー/カメラの画像をアプリ専用領域にコピーして永続化
/// - Supabase モード: さらに Storage の公開バケット `icons/<uuid>/` へ
///   アップロードし、公開URLを返す（これにより他のユーザーにもアイコン画像が見える）
/// アップロードに失敗した場合は端末内パスにフォールバックする。
class IconService {
  Future<String?> pickAndSave(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final iconsDir = Directory('${dir.path}${Platform.pathSeparator}icons');
    if (!iconsDir.existsSync()) {
      iconsDir.createSync(recursive: true);
    }
    final ts = DateTime.now().microsecondsSinceEpoch;
    final dest =
        '${iconsDir.path}${Platform.pathSeparator}icon_$ts.jpg';
    File(picked.path).copySync(dest);

    if (AppConfig.useSupabase) {
      try {
        final client = Supabase.instance.client;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          final bytes = File(dest).readAsBytesSync();
          final remotePath = '$uid/icon_$ts.jpg';
          await client.storage.from('icons').uploadBinary(
                remotePath,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
          return client.storage.from('icons').getPublicUrl(remotePath);
        }
      } catch (e) {
        // アップロード失敗時は端末内パスで続行（デバッグ用に記録のみ）
        debugPrint('icon upload failed: $e');
      }
    }
    return dest;
  }
}

/// グローバルインスタンス（本開発では DI / Riverpod Provider に置き換える）
final IconService iconService = IconService();

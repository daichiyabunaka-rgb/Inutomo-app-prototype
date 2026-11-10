import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

/// 画像の取得と保存（アイコン・保護犬/迷子犬の投稿写真など）。
/// - モックモード: ギャラリー/カメラの画像をアプリ専用領域にコピーして永続化
/// - Supabase モード: さらに Storage の公開バケット `bucket/<uuid>/` へ
///   アップロードし、公開URLを返す（これにより他のユーザーにも画像が見える）
/// アップロードに失敗した場合は端末内パスにフォールバックする。
class IconService {
  /// アイコン画像（600px四方に収める）
  Future<String?> pickAndSave(ImageSource source) {
    return _pickAndSave(
      source,
      subDir: 'icons',
      prefix: 'icon',
      bucket: 'icons',
      maxWidth: 600,
      maxHeight: 600,
    );
  }

  /// 保護犬・迷子犬の投稿写真（大きめに保存し、伝わりやすくする）
  Future<String?> pickProtectedDogPhoto(ImageSource source) {
    return _pickAndSave(
      source,
      subDir: 'dog_photos',
      prefix: 'dog_photo',
      bucket: 'protected-dog-photos',
      maxWidth: 1080,
      maxHeight: 1080,
    );
  }

  Future<String?> _pickAndSave(
    ImageSource source, {
    required String subDir,
    required String prefix,
    required String bucket,
    double? maxWidth,
    double? maxHeight,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final targetDir =
        Directory('${dir.path}${Platform.pathSeparator}$subDir');
    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }
    final ts = DateTime.now().microsecondsSinceEpoch;
    final dest =
        '${targetDir.path}${Platform.pathSeparator}${prefix}_$ts.jpg';
    File(picked.path).copySync(dest);

    if (AppConfig.useSupabase) {
      try {
        final client = Supabase.instance.client;
        final uid = client.auth.currentUser?.id;
        if (uid != null) {
          final bytes = File(dest).readAsBytesSync();
          final remotePath = '$uid/${prefix}_$ts.jpg';
          await client.storage.from(bucket).uploadBinary(
                remotePath,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
                  upsert: true,
                ),
              );
          return client.storage.from(bucket).getPublicUrl(remotePath);
        }
      } catch (e) {
        // アップロード失敗時は端末内パスで続行（デバッグ用に記録のみ）
        debugPrint('$prefix upload failed: $e');
      }
    }
    return dest;
  }
}

/// グローバルインスタンス（本開発では DI / Riverpod Provider に置き換える）
final IconService iconService = IconService();

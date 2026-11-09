import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/screens/home_shell.dart';
import 'src/screens/login_screen.dart';
import 'src/services/app_config.dart';
import 'src/services/app_state.dart';
import 'src/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Supabase のキーが --dart-define で渡されている場合のみ初期化する。
  // 未指定ならモックモード（端末内データ）として動作する。
  if (AppConfig.useSupabase) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.effectiveKey,
    );
  }
  await authService.init();
  // セッションが残っている場合は自動ログイン（domain状態を復元してホームへ）
  if (authService.hasSession) {
    final restored = await authService.buildSessionUser(
      lat: appState.anchorLat,
      lng: appState.anchorLng,
    );
    if (restored != null) {
      appState.attachUser(restored, reseed: true);
    }
  }
  runApp(const MeshitomoApp());
}

class MeshitomoApp extends StatelessWidget {
  const MeshitomoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '飯とも！（プロトタイプ）',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD9480F),
        ),
      ),
      home: ListenableBuilder(
        listenable: Listenable.merge([appState, authService]),
        builder: (_, _) =>
            appState.me == null ? const LoginScreen() : const HomeShell(),
      ),
    );
  }
}

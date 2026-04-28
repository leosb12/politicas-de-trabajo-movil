import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/notifications/push_notification_service.dart';
import 'core/storage/shared_preferences_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/views/auth_root_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService.bootstrap();
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const PoliticasNegocioApp(),
    ),
  );
}

class PoliticasNegocioApp extends StatelessWidget {
  const PoliticasNegocioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Politicas de Negocio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthRootView(),
    );
  }
}

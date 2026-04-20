import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:politicas_negocio_flutter/core/storage/shared_preferences_provider.dart';
import 'package:politicas_negocio_flutter/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Shows mobile login screen by default', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(preferences),
        ],
        child: const PoliticasNegocioApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Ingreso movil'), findsOneWidget);
    expect(find.text('Iniciar sesion'), findsOneWidget);
  });
}

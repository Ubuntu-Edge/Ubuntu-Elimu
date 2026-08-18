import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:denizen_ai/denizen_ai.dart';
import 'package:ubuntu_elimu/presentation/navigation/main_shell.dart';
import 'package:ubuntu_elimu/providers/navigation_provider.dart';
import 'package:ubuntu_elimu/providers/session_provider.dart';
import 'package:ubuntu_elimu/providers/document_provider.dart';
import 'package:ubuntu_elimu/providers/settings_provider.dart';
import 'package:ubuntu_elimu/providers/offline_model_provider.dart';

void main() {
  testWidgets('Smoke test for Ubuntu Elimu with Denizen AI integration', (WidgetTester tester) async {
    final navProvider = NavigationProvider();
    final docProvider = DocumentProvider();
    final modelProvider = OfflineModelProvider();
    final sessionProvider = SessionProvider();
    final settingsProvider = SettingsProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: navProvider),
          ChangeNotifierProvider.value(value: docProvider),
          ChangeNotifierProvider.value(value: modelProvider),
          ChangeNotifierProvider.value(value: sessionProvider),
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      ),
    );

    await tester.pump();

    // Verify greeting rendered on Home screen
    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('QUICK ACTIONS'), findsOneWidget);
  });

  test('Denizen AI models catalog lookup test', () {
    final models = DefaultOfflineModels.getMedicalModels();
    expect(models.isNotEmpty, isTrue);
  });
}

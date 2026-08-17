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
  setUp(() {
    DenizenAI.configure(
      edgeConfig: const UbuntuEdgeConfig(
        apiKey: 'ue-test-token',
        enableCloudFallback: false,
      ),
    );
  });

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

  test('Denizen AI Education models catalog lookup test', () {
    final educationModels = DefaultOfflineModels.getEducationModels();
    expect(educationModels.isNotEmpty, isTrue);

    final llama1b = DefaultOfflineModels.getModelById('llama-3.2-1b-q8');
    expect(llama1b, isNotNull);
    expect(llama1b!.name, contains('Llama 3.2 1B'));

    final allModels = DefaultOfflineModels.getAllRecommendedModels();
    expect(allModels.length, greaterThanOrEqualTo(educationModels.length));
  });
}

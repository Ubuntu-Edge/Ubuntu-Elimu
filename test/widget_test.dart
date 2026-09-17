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
import 'package:ubuntu_elimu/presentation/widgets/ue_markdown_text.dart';
import 'package:ubuntu_elimu/core/utils/text_sanitizer.dart';

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

  testWidgets('UEMarkdownText renders headers and formatted markdown without raw symbols', (WidgetTester tester) async {
    const rawMarkdown = '''
### Key Diagnosis
**Oral Rehydration Therapy** is the primary treatment.
- Give *zinc supplements* daily
1. First step: assess hydration
```
print("ORS dosage: 50ml/kg")
```
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UEMarkdownText(rawMarkdown),
        ),
      ),
    );

    await tester.pump();

    // Verify header rendered without ###
    expect(find.textContaining('Key Diagnosis'), findsOneWidget);
    expect(find.textContaining('###'), findsNothing);

    // Verify bold rendered without **
    expect(find.textContaining('Oral Rehydration Therapy'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
  });

  test('TextSanitizer cleans markdown and tokens for TTS', () {
    const raw = '<think>Let me reason</think>### Summary\n**Treatment:** - Give ORS';
    final cleaned = TextSanitizer.cleanOutput(raw);
    expect(cleaned.contains('<think>'), isFalse);
    expect(cleaned.contains('###'), isFalse);
    expect(cleaned.contains('**'), isFalse);
    expect(cleaned, equals('Summary\nTreatment: Give ORS'));
  });
}

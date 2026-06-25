import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'presentation/navigation/main_shell.dart';
import 'providers/navigation_provider.dart';
import 'providers/session_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/offline_model_provider.dart';
import 'providers/chat_provider.dart';

class UbuntuElimuApp extends StatelessWidget {
  final DocumentProvider? docProvider;
  final OfflineModelProvider? modelProvider;
  final SessionProvider? sessionProvider;

  const UbuntuElimuApp({
    super.key,
    this.docProvider,
    this.modelProvider,
    this.sessionProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider.value(value: sessionProvider ?? SessionProvider()),
        ChangeNotifierProvider.value(value: docProvider ?? DocumentProvider()),
        ChangeNotifierProvider.value(value: modelProvider ?? OfflineModelProvider()),
        ChangeNotifierProvider(
          create: (context) {
            final settings = SettingsProvider();
            // Attach after the tree is built so OfflineModelProvider is accessible
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final models = context.read<OfflineModelProvider>();
              settings.attachModelProvider(models);
            });
            return settings;
          },
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ChatProvider>(
          create: (context) => ChatProvider(
            Provider.of<SettingsProvider>(context, listen: false).getAIProvider(),
          ),
          update: (context, settings, chatProvider) {
            final provider = chatProvider ?? ChatProvider(settings.getAIProvider());
            provider.updateAIProvider(settings.getAIProvider());
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Ubuntu Elimu',
        debugShowCheckedModeBanner: false,
        theme: UETheme.darkTheme,
        home: const MainShell(),
      ),
    );
  }
}

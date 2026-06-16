import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/theme.dart';
import 'presentation/navigation/main_shell.dart';

// Providers
import 'providers/navigation_provider.dart';
import 'providers/document_provider.dart';
import 'providers/session_provider.dart';
import 'providers/settings_provider.dart';

class UbuntuElimuApp extends StatelessWidget {
  const UbuntuElimuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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

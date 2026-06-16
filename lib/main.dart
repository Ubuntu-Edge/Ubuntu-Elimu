import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/navigation/main_shell.dart';
import 'providers/navigation_provider.dart';
import 'providers/session_provider.dart';
import 'providers/document_provider.dart';
import 'providers/settings_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => DocumentProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: const UbuntuElimuApp(),
    ),
  );
}

class UbuntuElimuApp extends StatelessWidget {
  const UbuntuElimuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ubuntu Elimu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
      ),
      home: const MainShell(),
    );
  }
}

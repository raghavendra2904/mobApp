import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/history_screen.dart';
import 'screens/instructions_screen.dart';
import 'screens/crash_log_screen.dart';

class NeckAlertApp extends StatelessWidget {
  const NeckAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neck Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D6B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white, fontSize: 16),
          titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/analytics': (_) => const AnalyticsScreen(),
        '/history': (_) => const HistoryScreen(),
        '/instructions': (_) => const InstructionsScreen(),
        '/crashlog': (_) => const CrashLogScreen(),
      },
    );
  }
}

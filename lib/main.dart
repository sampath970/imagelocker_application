import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/memory.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MemoryAdapter());
  await Hive.openBox<Memory>('memoriesBox');

  runApp(const TimeLockApp());
}

class TimeLockApp extends StatefulWidget {
  const TimeLockApp({super.key});

  @override
  State<TimeLockApp> createState() => _TimeLockAppState();
}

class _TimeLockAppState extends State<TimeLockApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeLock App',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
        ),
      ),
      themeMode: _themeMode,
      // Always start at lock screen
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/home': (context) => HomeScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
        '/auth': (context) => const AuthScreen(),
        '/pin': (context) => const PinScreen(),
      },
    );
  }
}

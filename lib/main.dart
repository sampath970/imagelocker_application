import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/memory.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pin_screen.dart';
import 'app_lock_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(MemoryAdapter());
  await Hive.openBox<Memory>('memoriesBox');
  AppLockManager().init();

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
      _themeMode =
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  void dispose() {
    AppLockManager().disposeManager();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppLockManager>.value(
      value: AppLockManager(),
      child: MaterialApp(
        title: 'TimeLock App',
        theme: ThemeData(
          brightness: Brightness.light,
          primarySwatch: Colors.blue,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1C1C1E),
          ),
        ),
        themeMode: _themeMode,
        home: _RootScreen(
          onToggleTheme: _toggleTheme,
          isDarkMode: _themeMode == ThemeMode.dark,
        ),
        debugShowCheckedModeBanner: false,
        routes: {
          '/home': (context) => HomeScreen(
            onToggleTheme: _toggleTheme,
            isDarkMode: _themeMode == ThemeMode.dark,
          ),
          '/auth': (context) => const AuthScreen(),
          '/pin': (context) => const PinScreen(),
        },
      ),
    );
  }
}

class _RootScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  const _RootScreen({
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppLockManager>(
      builder: (context, lockManager, _) {
        if (lockManager.shouldLock) {
          return AuthScreen(
            onUnlock: () {
              lockManager.unlock();
              Navigator.of(context).pushReplacementNamed('/home');
            },
          );
        }
        return HomeScreen(
          onToggleTheme: onToggleTheme,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}

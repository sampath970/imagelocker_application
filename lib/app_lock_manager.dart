import 'package:flutter/widgets.dart';

class AppLockManager extends ChangeNotifier with WidgetsBindingObserver {
  static final AppLockManager _instance = AppLockManager._internal();
  factory AppLockManager() => _instance;
  AppLockManager._internal();

  bool _shouldLock = false; // Set to true when backgrounded

  bool get shouldLock => _shouldLock;

  // Call this on init in main.dart
  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  // Call this on dispose in main.dart
  void disposeManager() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _shouldLock = true;
      notifyListeners();
    }
  }

  void unlock() {
    _shouldLock = false;
    notifyListeners();
  }
}

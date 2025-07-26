import 'package:flutter/widgets.dart';

class AppLockManager extends ChangeNotifier with WidgetsBindingObserver {
  static final AppLockManager _instance = AppLockManager._internal();
  factory AppLockManager() => _instance;
  AppLockManager._internal();

  bool _shouldLock = true; // Always true on app startup.

  bool get shouldLock => _shouldLock;

  void unlock() {
    _shouldLock = false;
    notifyListeners();
  }

  void lock() {
    _shouldLock = true;
    notifyListeners();
  }

  void init() {
    WidgetsBinding.instance.addObserver(this);
  }

  void disposeManager() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lock on background, screen off, task switch
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _shouldLock = true;
      notifyListeners();
    }
    // Ensure lock triggers *also* on resume (coming forward from recents)
    if (state == AppLifecycleState.resumed && _shouldLock) {
      notifyListeners();
    }
  }
}

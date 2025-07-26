import 'package:hive/hive.dart';

class PinHelper {
  static const String _boxName = 'pinBox';
  static const String _pinKey = 'user_pin';

  static Future<void> savePin(String pin) async {
    final box = await Hive.openBox(_boxName);
    await box.put(_pinKey, pin);
  }

  static Future<String?> getPin() async {
    final box = await Hive.openBox(_boxName);
    return box.get(_pinKey);
  }

  static Future<void> clearPin() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_pinKey);
  }
}

import 'package:shared_preferences/shared_preferences.dart';
import 'cart_storage_base.dart';

class SharedPrefsCartStorage implements CartStorage {
  static const String _key = 'cart_state_items';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  @override
  Future<void> write(String data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, data);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

CartStorage buildCartStorage() => SharedPrefsCartStorage();

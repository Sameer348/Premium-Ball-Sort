import 'package:shared_preferences/shared_preferences.dart';

/// Minimal storage abstraction so repositories can be tested in memory and
/// swapped for a cloud-backed store later.
abstract class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class SharedPrefsStore implements KeyValueStore {
  SharedPrefsStore(this._prefs);
  final SharedPreferences _prefs;

  static Future<SharedPrefsStore> create() async => SharedPrefsStore(await SharedPreferences.getInstance());

  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);
  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

class MemoryStore implements KeyValueStore {
  final Map<String, String> data = {};
  @override
  String? getString(String key) => data[key];
  @override
  Future<void> setString(String key, String value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
}

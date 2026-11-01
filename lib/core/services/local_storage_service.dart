import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();

  static final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  static const String tasksKey = 'taskflow_tasks_v1';
  static const String projectsKey = 'taskflow_projects_v1';

  static final Map<String, Future<void>> _writeQueues = {};

  static Future<void> saveList(String key, List<Map<String, dynamic>> data) {
    // Encode immediately to capture this version
    // of the data before any later state changes.
    final jsonString = jsonEncode(data);

    final previous = _writeQueues[key] ?? Future<void>.value();

    final next = previous
        .catchError((Object error) {
          // Keep the queue running after a failed write.
        })
        .then((_) => _prefs.setString(key, jsonString));

    _writeQueues[key] = next;

    return next;
  }

  static Future<List<Map<String, dynamic>>?> loadList(String key) async {
    final pendingWrite = _writeQueues[key];

    if (pendingWrite != null) {
      await pendingWrite;
    }

    final jsonString = await _prefs.getString(key);

    if (jsonString == null) return null;

    final decoded = jsonDecode(jsonString);

    if (decoded is! List) {
      throw const FormatException('Saved data is not a list.');
    }

    return decoded.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid saved item.');
      }

      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Future<void> remove(String key) async {
    final pendingWrite = _writeQueues[key];

    if (pendingWrite != null) {
      await pendingWrite;
    }

    await _prefs.remove(key);
  }
}

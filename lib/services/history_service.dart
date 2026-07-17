import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/download_history_entry.dart';

/// Persiste el historial de descargas localmente con shared_preferences.
class HistoryService {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _prefsKey = 'download_history';

  /// Devuelve el historial ordenado de la más reciente a la más antigua.
  Future<List<DownloadHistoryEntry>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    return raw
        .map((s) => DownloadHistoryEntry.fromJson(
            jsonDecode(s) as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<void> add(DownloadHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_prefsKey, raw);
  }

  Future<void> remove(DownloadHistoryEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    raw.removeWhere((s) {
      final e =
          DownloadHistoryEntry.fromJson(jsonDecode(s) as Map<String, dynamic>);
      return e.path == entry.path && e.date == entry.date;
    });
    await prefs.setStringList(_prefsKey, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

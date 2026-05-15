import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'scanned_area_model.dart';

class PlayAreaStorage {
  const PlayAreaStorage();

  static const _key = 'phonepong.playArea';

  Future<void> save(ScannedAreaModel area) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(area.markReady().toJson()));
  }

  Future<ScannedAreaModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;

    return ScannedAreaModel.fromJson(decoded.cast<String, Object?>());
  }
}

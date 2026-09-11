import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Loads JSON config files from `assets/data/`.
///
/// Screens keep their copy (text), colors, and image paths out of Dart
/// source and in these JSON assets instead, so they can be edited later
/// without touching code.
class AppConfigLoader {
  const AppConfigLoader._();

  static final Map<String, Map<String, dynamic>> _cache = {};

  /// Loads and caches the JSON object at [assetPath]
  /// (e.g. `assets/data/splash_screen.json`).
  static Future<Map<String, dynamic>> load(String assetPath) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    _cache[assetPath] = decoded;
    return decoded;
  }
}

import 'package:flutter/material.dart';

/// Parses a `"#RRGGBB"` or `"#AARRGGBB"` string (as used in the JSON assets
/// under `assets/data/`) into a [Color].
Color colorFromHex(String hex) {
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  return Color(int.parse(value, radix: 16));
}

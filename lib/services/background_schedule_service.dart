import 'dart:async';

import 'package:flutter/foundation.dart';

import 'app_config_loader.dart';

const _dayNames = {
  1: 'mon',
  2: 'tue',
  3: 'wed',
  4: 'thu',
  5: 'fri',
  6: 'sat',
  7: 'sun',
};

/// One entry in a day's schedule from `assets/data/background_schedule.json`:
/// [background] applies from [startMinutes] (minutes since midnight) until
/// the next entry that day (or until midnight if it's the last one).
class _DaySlot {
  const _DaySlot({required this.startMinutes, required this.background});

  final int startMinutes;
  final String background;

  factory _DaySlot.fromJson(Map<String, dynamic> json) {
    return _DaySlot(
      startMinutes: _parseTimeToMinutes(json['start'] as String),
      background: json['background'] as String,
    );
  }

  static int _parseTimeToMinutes(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return hour * 60 + minute;
  }
}

/// Picks the chat background image for the current moment, following a
/// weekly, 30-minute-slot schedule edited in
/// `assets/data/background_schedule.json` — each day lists `{start,
/// background}` entries; the image for the latest `start` at or before now
/// applies until the next one. Falls back to `defaultBackground` for any
/// time before a day's first entry. Re-checks periodically so the
/// background updates live while a chat is open.
class BackgroundScheduleService extends ChangeNotifier {
  BackgroundScheduleService._(this._week, this._defaultBackground) {
    _current = _resolve(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  static const _configPath = 'assets/data/background_schedule.json';

  final Map<String, List<_DaySlot>> _week;
  final String _defaultBackground;
  late Timer _timer;
  late String _current;

  String get current => _current;

  static Future<BackgroundScheduleService> load() async {
    final json = await AppConfigLoader.load(_configPath);
    final weekJson = json['week'] as Map<String, dynamic>;
    final week = {
      for (final entry in weekJson.entries)
        entry.key: (entry.value as List)
            .map((e) => _DaySlot.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes)),
    };
    return BackgroundScheduleService._(
      week,
      json['defaultBackground'] as String,
    );
  }

  String _resolve(DateTime now) {
    final slots = _week[_dayNames[now.weekday]];
    if (slots == null || slots.isEmpty) return _defaultBackground;

    final nowMinutes = now.hour * 60 + now.minute;
    var result = _defaultBackground;
    for (final slot in slots) {
      if (slot.startMinutes > nowMinutes) break;
      result = slot.background;
    }
    return result;
  }

  void _tick() {
    final resolved = _resolve(DateTime.now());
    if (resolved != _current) {
      _current = resolved;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }
}

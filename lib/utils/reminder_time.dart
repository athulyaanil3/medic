import 'package:flutter/material.dart';

/// Canonical storage format for medicine reminders: 24-hour "HH:mm".
String formatReminderTime(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Parse stored or legacy locale strings ("8:00 AM", "08:30", etc.).
({int hour, int minute})? parseReminderTime(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return null;

  // Already 24h HH:mm
  final m24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s);
  if (m24 != null) {
    final h = int.parse(m24.group(1)!);
    final min = int.parse(m24.group(2)!);
    if (h >= 0 && h <= 23 && min >= 0 && min <= 59) {
      return (hour: h, minute: min);
    }
    return null;
  }

  // 12h with optional AM/PM
  final upper = s.toUpperCase();
  final isPm = upper.contains('PM');
  final isAm = upper.contains('AM');
  final digits = s.replaceAll(RegExp(r'[^0-9:]'), '');
  final parts = digits.split(':');
  if (parts.length < 2) return null;

  var h = int.tryParse(parts[0]);
  var min = int.tryParse(parts[1]);
  if (h == null || min == null) return null;

  if (isAm || isPm) {
    if (h == 12) {
      h = isAm ? 0 : 12;
    } else if (isPm) {
      h += 12;
    }
  }

  if (h < 0 || h > 23 || min < 0 || min > 59) return null;
  return (hour: h, minute: min);
}

/// Normalize to HH:mm for Hive storage.
String normalizeReminderTime(String raw) {
  final p = parseReminderTime(raw);
  if (p == null) return raw.trim();
  return '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}';
}

List<String> normalizeReminderTimes(List<String> times) {
  final out = <String>[];
  for (final t in times) {
    final n = normalizeReminderTime(t);
    if (parseReminderTime(n) != null && !out.contains(n)) {
      out.add(n);
    }
  }
  out.sort();
  return out;
}

/// Friendly label for UI chips.
String displayReminderTime(String stored) {
  final p = parseReminderTime(stored);
  if (p == null) return stored;
  final h = p.hour;
  final m = p.minute;
  final period = h >= 12 ? 'PM' : 'AM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $period';
}

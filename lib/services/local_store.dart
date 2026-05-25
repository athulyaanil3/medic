import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../models/food_entry.dart';
import '../models/medicine.dart';

class LocalStore {

  // BOX NAMES

  static const medicinesBoxId =
      'medicines';

  static const foodBoxId =
      'food_logs';

  static const settingsBoxId =
      'app_settings';

  // DEFAULT VALUES

  static const defaultCalorieGoal =
  2000;

  static const defaultWaterGoalMl =
  2500;

  // INITIALIZE HIVE

  static Future<void> init() async {

    await Hive.initFlutter();

    await Future.wait([

      Hive.openBox(
        medicinesBoxId,
      ),

      Hive.openBox(
        foodBoxId,
      ),

      Hive.openBox(
        settingsBoxId,
      ),
    ]);
  }

  // BOXES

  static Box _medBox() {

    if (!Hive.isBoxOpen(
      medicinesBoxId,
    )) {

      throw HiveError(
        'Medicines box is not open.',
      );
    }

    return Hive.box(
      medicinesBoxId,
    );
  }

  static Box _foodBox() {

    if (!Hive.isBoxOpen(
      foodBoxId,
    )) {

      throw HiveError(
        'Food box is not open.',
      );
    }

    return Hive.box(
      foodBoxId,
    );
  }

  static Box _settingsBox() {

    if (!Hive.isBoxOpen(
      settingsBoxId,
    )) {

      throw HiveError(
        'Settings box is not open.',
      );
    }

    return Hive.box(
      settingsBoxId,
    );
  }

  // SAFE INT PARSER

  static int _readInt(
      dynamic v,
      int fallback,
      ) {

    if (v is int) {
      return v;
    }

    if (v is num) {
      return v.toInt();
    }

    return fallback;
  }

  // DATE KEY

  static String _dayKey(
      DateTime d,
      ) {

    return

      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  // =========================
  // MEDICINES
  // =========================

  static Future<void>
  upsertMedicine(
      Medicine m,
      ) async {

    await _medBox().put(

      m.id,

      jsonEncode(
        m.toMap(),
      ),
    );
  }

  static Future<void>
  deleteMedicine(
      String id,
      ) async {

    await _medBox().delete(id);
  }

  static List<Medicine>
  readMedicines() {

    final out = <Medicine>[];

    for (final key
    in _medBox().keys) {

      final raw =
      _medBox().get(key);

      if (raw is String) {

        try {

          out.add(

            Medicine.fromMap(

              jsonDecode(raw)
              as Map<String, dynamic>,
            ),
          );

        } catch (_) {}
      }
    }

    out.sort(

          (a, b) =>
          a.name.compareTo(
            b.name,
          ),
    );

    return out;
  }

  // =========================
  // FOOD LOGS
  // =========================

  static Future<void>
  upsertFood(
      FoodEntry e,
      ) async {

    await _foodBox().put(

      e.id,

      jsonEncode(
        e.toMap(),
      ),
    );
  }

  static Future<void>
  deleteFood(
      String id,
      ) async {

    await _foodBox().delete(id);
  }

  static List<FoodEntry>
  readFoodSince(
      DateTime from,
      ) {

    final out = <FoodEntry>[];

    for (final key
    in _foodBox().keys) {

      final raw =
      _foodBox().get(key);

      if (raw is! String) {
        continue;
      }

      try {

        final entry =
        FoodEntry.fromMap(

          jsonDecode(raw)
          as Map<String, dynamic>,
        );

        if (!entry.at
            .isBefore(from)) {

          out.add(entry);
        }

      } catch (_) {
        continue;
      }
    }

    out.sort(

          (a, b) =>
          b.at.compareTo(
            a.at,
          ),
    );

    return out;
  }

  static List<FoodEntry>
  readToday() {

    final now =
    DateTime.now();

    final start =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    return readFoodSince(
      start,
    );
  }

  static int
  todayCalorieTotal() {

    return readToday().fold<int>(

      0,

          (s, e) =>
      s + e.calories,
    );
  }

  static FoodEntry?
  lastLoggedMeal() {

    final week =
    readFoodSince(

      DateTime.now().subtract(
        const Duration(days: 7),
      ),
    );

    return week.isEmpty
        ? null
        : week.first;
  }

  // =========================
  // CALORIE GOAL
  // =========================

  static int
  readCalorieGoal() {

    if (!Hive.isBoxOpen(
      settingsBoxId,
    )) {

      return defaultCalorieGoal;
    }

    final v =
    _settingsBox().get(
      'calorie_goal',
    );

    return _readInt(

      v,

      defaultCalorieGoal,

    ).clamp(
      1000,
      5000,
    );
  }

  static Future<void>
  writeCalorieGoal(
      int goal,
      ) async {

    if (!Hive.isBoxOpen(
      settingsBoxId,
    )) {

      await Hive.openBox(
        settingsBoxId,
      );
    }

    await _settingsBox().put(

      'calorie_goal',

      goal.clamp(
        1000,
        5000,
      ),
    );
  }

  // =========================
  // WATER TRACKING
  // =========================

  static int
  readWaterMlToday() {

    if (!Hive.isBoxOpen(
      settingsBoxId,
    )) {

      return 0;
    }

    final today =
    _dayKey(
      DateTime.now(),
    );

    if (_settingsBox().get(
      'water_day',
    ) !=
        today) {

      return 0;
    }

    return _readInt(

      _settingsBox().get(
        'water_ml',
      ),

      0,
    );
  }

  static Future<void>
  writeWaterMlToday(
      int ml,
      ) async {

    if (!Hive.isBoxOpen(
      settingsBoxId,
    )) {

      await Hive.openBox(
        settingsBoxId,
      );
    }

    final today =
    _dayKey(
      DateTime.now(),
    );

    await _settingsBox().put(
      'water_day',
      today,
    );

    await _settingsBox().put(

      'water_ml',

      ml.clamp(
        0,
        6000,
      ),
    );
  }

  // =========================
  // VOICE REMINDERS
  // =========================

  static bool get isInitialized =>
      Hive.isBoxOpen(medicinesBoxId) &&
      Hive.isBoxOpen(foodBoxId) &&
      Hive.isBoxOpen(settingsBoxId);

  static bool readVoiceRemindersEnabled() {
    if (!Hive.isBoxOpen(settingsBoxId)) return true;
    return _settingsBox().get('voice_reminders_enabled', defaultValue: true) as bool;
  }

  static Future<void> writeVoiceRemindersEnabled(bool enabled) async {
    if (!Hive.isBoxOpen(settingsBoxId)) {
      await Hive.openBox(settingsBoxId);
    }
    await _settingsBox().put('voice_reminders_enabled', enabled);
  }

  static String _voiceTextKey(int alarmId) => 'voice_text_$alarmId';
  static String _voiceMetaKey(int alarmId) => 'voice_meta_$alarmId';

  static Future<void> writeReminderVoice({
    required int alarmId,
    required String text,
    required int hour,
    required int minute,
  }) async {
    if (!Hive.isBoxOpen(settingsBoxId)) {
      await Hive.openBox(settingsBoxId);
    }
    await _settingsBox().put(_voiceTextKey(alarmId), text);
    await _settingsBox().put(
      _voiceMetaKey(alarmId),
      jsonEncode({'hour': hour, 'minute': minute}),
    );
  }

  static String? readReminderVoiceText(int alarmId) {
    if (!Hive.isBoxOpen(settingsBoxId)) return null;
    final v = _settingsBox().get(_voiceTextKey(alarmId));
    return v?.toString();
  }

  static ({int hour, int minute})? readReminderVoiceMeta(int alarmId) {
    if (!Hive.isBoxOpen(settingsBoxId)) return null;
    final raw = _settingsBox().get(_voiceMetaKey(alarmId));
    if (raw is! String) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return (
        hour: _readInt(map['hour'], 8),
        minute: _readInt(map['minute'], 0),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> deleteReminderVoice(int alarmId) async {
    if (!Hive.isBoxOpen(settingsBoxId)) return;
    await _settingsBox().delete(_voiceTextKey(alarmId));
    await _settingsBox().delete(_voiceMetaKey(alarmId));
  }
}
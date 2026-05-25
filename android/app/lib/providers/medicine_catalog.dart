import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/medicine.dart';
import '../services/cloud_sync_service.dart';
import '../services/local_store.dart';
import '../services/notification_service.dart';

class MedicineCatalog extends ChangeNotifier {

  MedicineCatalog() {

    reload();
  }

  final _uuid = const Uuid();

  List<Medicine> _items = [];

  String? _lastScheduleMessage;

  List<Medicine> get items =>
      List.unmodifiable(_items);

  int get count =>
      _items.length;

  void reload() {

    _items =
        LocalStore.readMedicines();

    notifyListeners();
  }

  Future<void>
  syncWithCloudAndReschedule()
  async {

    try {

      await CloudSyncService
          .instance
          .mergeFromCloud();

    } catch (e) {

      if (kDebugMode) {

        debugPrint(
          'Cloud sync: $e',
        );
      }
    }

    reload();

    try {

      await rescheduleAllMedicineNotifications(
        _items,
      );

    } catch (e) {

      if (kDebugMode) {

        debugPrint(
          'Reschedule notifications: $e',
        );
      }
    }

    notifyListeners();
  }

  // ADD MEDICINE
  Future<String?> addMedicine({

    required String name,

    required String dosage,

    required List<String>
    reminderTimes,

    // NEW
    required List<String>
    repeatDays,

    String? notes,

  }) async {

    if (name.trim().isEmpty) {

      return 'Medicine name is required.';
    }

    if (reminderTimes.isEmpty) {

      return 'Add at least one reminder time.';
    }

    final medicine =
    Medicine(

      id: _uuid.v4(),

      name: name.trim(),

      dosage: dosage.trim(),

      reminderTimes:
      reminderTimes,

      // NEW
      repeatDays:
      repeatDays,

      notes:
      (notes == null ||
          notes.trim().isEmpty)

          ? null

          : notes.trim(),
    );

    await LocalStore
        .upsertMedicine(
      medicine,
    );

    _items =
        LocalStore.readMedicines();

    await _rescheduleAllWithFeedback();

    notifyListeners();

    unawaited(

      CloudSyncService.instance
          .pushMedicine(
        medicine,
      ),
    );

    return _lastScheduleMessage;
  }

  // EDIT MEDICINE
  Future<String?> replaceMedicine(

      Medicine old, {

        required String name,

        required String dosage,

        required List<String>
        reminderTimes,

        // NEW
        required List<String>
        repeatDays,

        String? notes,

      }) async {

    await cancelMedicineNotifications(
      old,
    );

    final updated =
    Medicine(

      id: old.id,

      name: name.trim(),

      dosage: dosage.trim(),

      reminderTimes:
      reminderTimes,

      // NEW
      repeatDays:
      repeatDays,

      notes:
      (notes == null ||
          notes.trim().isEmpty)

          ? null

          : notes.trim(),

      createdAt:
      old.createdAt,
    );

    await LocalStore
        .upsertMedicine(
      updated,
    );

    _items =
        LocalStore.readMedicines();

    await _rescheduleAllWithFeedback();

    notifyListeners();

    unawaited(

      CloudSyncService.instance
          .pushMedicine(
        updated,
      ),
    );

    return _lastScheduleMessage;
  }

  // DELETE MEDICINE
  Future<void> removeMedicine(
      Medicine medicine,
      ) async {

    await cancelMedicineNotifications(
      medicine,
    );

    await LocalStore
        .deleteMedicine(
      medicine.id,
    );

    _items =
        LocalStore.readMedicines();

    await _rescheduleAllWithFeedback();

    notifyListeners();

    unawaited(

      CloudSyncService.instance
          .deleteRemoteMedicine(
        medicine.id,
      ),
    );
  }

  // RESCHEDULE
  Future<void>
  _rescheduleAllWithFeedback()
  async {

    try {

      await rescheduleAllMedicineNotifications(
        _items,
      );

      final status =
      await getReminderPermissionStatus();

      _lastScheduleMessage =
      status.ready

          ? null

          : (status.setupHint ??

          'Enable notifications for reminders.');

    } catch (e) {

      if (kDebugMode) {

        debugPrint(
          'Reschedule all: $e',
        );
      }

      _lastScheduleMessage =
      'Saved. Allow notifications for reminders.';
    }
  }
}
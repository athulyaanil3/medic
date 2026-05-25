import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

  int get count => _items.length;

  // RELOAD LOCAL DATA

  void reload() {

    _items =
        LocalStore.readMedicines();

    notifyListeners();
  }

  // CLOUD SYNC

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

    required List<String>
    repeatDays,

    // NEW
    required int stock,

    // NEW
    required int dailyDose,

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

      repeatDays:
      repeatDays,

      // NEW
      stock: stock,

      // NEW
      dailyDose:
      dailyDose,

      notes:
      (notes == null ||
          notes.trim().isEmpty)

          ? null

          : notes.trim(),
    );

    // SAVE LOCAL

    await LocalStore
        .upsertMedicine(
      medicine,
    );

    _items =
        LocalStore.readMedicines();

    // RESCHEDULE NOTIFICATIONS

    await _rescheduleAllWithFeedback();

    _notifyAfterFrame();

    // CLOUD PUSH

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

        required List<String>
        repeatDays,

        // NEW
        required int stock,

        // NEW
        required int dailyDose,

        String? notes,

      }) async {

    // CANCEL OLD NOTIFICATIONS

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

      repeatDays:
      repeatDays,

      // NEW
      stock: stock,

      // NEW
      dailyDose:
      dailyDose,

      notes:
      (notes == null ||
          notes.trim().isEmpty)

          ? null

          : notes.trim(),

      createdAt:
      old.createdAt,
    );

    // SAVE UPDATED

    await LocalStore
        .upsertMedicine(
      updated,
    );

    _items =
        LocalStore.readMedicines();

    // RESCHEDULE

    await _rescheduleAllWithFeedback();

    _notifyAfterFrame();

    // CLOUD UPDATE

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

    // CANCEL NOTIFICATIONS

    await cancelMedicineNotifications(
      medicine,
    );

    // DELETE LOCAL

    await LocalStore
        .deleteMedicine(
      medicine.id,
    );

    _items =
        LocalStore.readMedicines();

    // RESCHEDULE

    await _rescheduleAllWithFeedback();

    notifyListeners();

    // DELETE CLOUD

    unawaited(

      CloudSyncService.instance
          .deleteRemoteMedicine(
        medicine.id,
      ),
    );
  }

  // REDUCE STOCK

  Future<void> reduceStock(
      Medicine medicine,
      ) async {

    if (medicine.stock <= 0 || medicine.dailyDose <= 0) return;

    int updatedStock =
        medicine.stock -
            medicine.dailyDose;

    if (updatedStock < 0) {
      updatedStock = 0;
    }

    final updatedMedicine =
    Medicine(

      id: medicine.id,

      name: medicine.name,

      dosage: medicine.dosage,

      reminderTimes:
      medicine.reminderTimes,

      repeatDays:
      medicine.repeatDays,

      stock: updatedStock,

      dailyDose:
      medicine.dailyDose,

      notes:
      medicine.notes,

      createdAt:
      medicine.createdAt,
    );

    await LocalStore
        .upsertMedicine(
      updatedMedicine,
    );

    _items =
        LocalStore.readMedicines();

    notifyListeners();

    // LOW STOCK ALERT

    if (updatedStock <= 3) {

      if (kDebugMode) {

        debugPrint(
          '${medicine.name} stock is running low.',
        );
      }
    }
  }

  // RESCHEDULE ALL

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

  void _notifyAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!hasListeners) return;
      notifyListeners();
    });
  }
}
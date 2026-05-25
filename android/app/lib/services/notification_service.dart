import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/medicine.dart';

final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

AndroidFlutterLocalNotificationsPlugin? get _android =>
    _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

/// Whether the device can show medicine reminders at chosen times.
class ReminderPermissionStatus {
  const ReminderPermissionStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsEnabled,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsEnabled;

  bool get ready => notificationsEnabled;

  String? get setupHint {
    if (!notificationsEnabled) {
      return 'Turn on notifications for MediVoice in system settings.';
    }
    if (!exactAlarmsEnabled) {
      return 'Allow alarms & reminders so doses fire at the exact time you set.';
    }
    return null;
  }
}

class NotificationScheduleResult {
  const NotificationScheduleResult({required this.ok, this.message, this.scheduledCount = 0});

  final bool ok;
  final String? message;
  final int scheduledCount;
}

Future<void> initNotifications() async {
  tz_data.initializeTimeZones();
  await _configureLocalTimeZone();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifications.initialize(
    const InitializationSettings(
      android: androidInit,
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (response) {
      if (kDebugMode) {
        debugPrint('Notification tapped: ${response.payload}');
      }
    },
  );

  const channel = AndroidNotificationChannel(
    'medic_reminders_v1',
    'Medicine reminders',
    description: 'Daily medicine dose reminders at your chosen times',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );
  await _android?.createNotificationChannel(channel);

  await ensureReminderPermissions(requestIfNeeded: true);
}

Future<void> _configureLocalTimeZone() async {
  try {
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    if (kDebugMode) debugPrint('Notification timezone: ${tzInfo.identifier}');
    return;
  } catch (e) {
    if (kDebugMode) debugPrint('FlutterTimezone failed: $e');
  }

  // Fallback: guess from device offset (common India UTC+5:30).
  final offset = DateTime.now().timeZoneOffset;
  final hours = offset.inHours;
  if (hours == 5 && offset.inMinutes % 60 == 30) {
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    return;
  }
  tz.setLocalLocation(tz.getLocation('UTC'));
  if (kDebugMode) debugPrint('Notification timezone fallback: UTC');
}

Future<ReminderPermissionStatus> getReminderPermissionStatus() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final notificationsEnabled = await _android?.areNotificationsEnabled() ?? false;
    final exactAlarmsEnabled = await _android?.canScheduleExactNotifications() ?? false;
    return ReminderPermissionStatus(
      notificationsEnabled: notificationsEnabled,
      exactAlarmsEnabled: exactAlarmsEnabled,
    );
  }
  final notif = await Permission.notification.status;
  return ReminderPermissionStatus(
    notificationsEnabled: notif.isGranted,
    exactAlarmsEnabled: true,
  );
}

/// Requests notification + exact-alarm permission (Android 12+).
Future<ReminderPermissionStatus> ensureReminderPermissions({bool requestIfNeeded = true}) async {
  if (requestIfNeeded) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _android?.requestNotificationsPermission();
      await _android?.requestExactAlarmsPermission();
    } else {
      await Permission.notification.request();
    }
  }
  return getReminderPermissionStatus();
}

Future<void> openReminderPermissionSettings() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    final status = await getReminderPermissionStatus();
    if (!status.exactAlarmsEnabled) {
      await _android?.requestExactAlarmsPermission();
      return;
    }
  }
  await openAppSettings();
}

/// Unique per medicine + time slot (supports many medicines without ID clashes).
int reminderNotificationId(String medicineId, int slotIndex) {
  final combined = Object.hash(medicineId, slotIndex);
  return (combined & 0x7fffffff).clamp(1, 2147483646);
}

Future<void> cancelMedicineNotifications(Medicine m) async {
  for (var i = 0; i < m.reminderTimes.length; i++) {
    await _notifications.cancel(reminderNotificationId(m.id, i));
  }
}

Future<void> rescheduleAllMedicineNotifications(List<Medicine> meds) async {
  await _notifications.cancelAll();
  for (final m in meds) {
    await scheduleMedicineNotifications(m);
  }
}

Future<NotificationScheduleResult> scheduleMedicineNotifications(Medicine medicine) async {
  final permission = await ensureReminderPermissions(requestIfNeeded: true);
  if (!permission.ready) {
    return NotificationScheduleResult(
      ok: false,
      message: permission.setupHint ?? 'Enable notifications to get dose reminders.',
    );
  }

  final canExact = defaultTargetPlatform == TargetPlatform.android
      ? (await _android?.canScheduleExactNotifications() ?? false)
      : true;
  final scheduleMode = canExact
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentSound: true,
    presentBadge: true,
    interruptionLevel: InterruptionLevel.timeSensitive,
  );

  var scheduled = 0;
  String? lastError;

  for (var i = 0; i < medicine.reminderTimes.length; i++) {
    final hm = medicine.reminderTimes[i].split(':');
    if (hm.length != 2) continue;
    final h = int.tryParse(hm[0]);
    final min = int.tryParse(hm[1]);
    if (h == null || min == null || h > 23 || min > 59) continue;

    final when = _nextOccurrence(h, min);
    final androidDetails = AndroidNotificationDetails(
      'medic_reminders_v1',
      'Medicine reminders',
      channelDescription: 'Daily medicine reminder times.',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      styleInformation: BigTextStyleInformation(
        medicine.dosage.isEmpty ? 'Time to take your medicine' : medicine.dosage,
      ),
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    final id = reminderNotificationId(medicine.id, i);

    try {
      await _notifications.zonedSchedule(
        id,
        '💊 ${medicine.name}',
        medicine.dosage.isNotEmpty
            ? medicine.dosage
            : 'Reminder • ${medicine.reminderTimes[i]}',
        when,
        details,
        payload: medicine.id,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      scheduled++;
      if (kDebugMode) {
        debugPrint('Scheduled ${medicine.name} @ ${medicine.reminderTimes[i]} → $when (exact=$canExact)');
      }
    } catch (e) {
      lastError = e.toString();
      if (kDebugMode) debugPrint('Schedule failed ($scheduleMode): $e');
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        try {
          await _notifications.zonedSchedule(
            id,
            '💊 ${medicine.name}',
            medicine.dosage.isNotEmpty
                ? medicine.dosage
                : 'Reminder • ${medicine.reminderTimes[i]}',
            when,
            details,
            payload: medicine.id,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          scheduled++;
        } catch (e2) {
          lastError = e2.toString();
          if (kDebugMode) debugPrint('Inexact schedule also failed: $e2');
        }
      }
    }
  }

  if (scheduled == 0) {
    return NotificationScheduleResult(
      ok: false,
      message: lastError ?? 'Could not schedule reminders. Check notification & alarm permissions.',
    );
  }

  if (!permission.exactAlarmsEnabled) {
    return NotificationScheduleResult(
      ok: true,
      scheduledCount: scheduled,
      message: 'Reminders set. Allow "Alarms & reminders" in settings for exact times.',
    );
  }

  return NotificationScheduleResult(ok: true, scheduledCount: scheduled);
}

/// Next daily occurrence in local timezone. If today's time just passed (< 3 min), fire soon.
tz.TZDateTime _nextOccurrence(int hour, int minute) {
  final now = tz.TZDateTime.now(tz.local);
  var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

  if (!scheduled.isAfter(now)) {
    final lateBy = now.difference(scheduled);
    if (lateBy.inMinutes < 3) {
      return now.add(const Duration(seconds: 15));
    }
    scheduled = scheduled.add(const Duration(days: 1));
  }
  return scheduled;
}

/// Debug: show a test notification immediately (proves permissions work).
Future<void> showTestReminderNotification() async {
  const androidDetails = AndroidNotificationDetails(
    'medic_reminders_v1',
    'Medicine reminders',
    importance: Importance.max,
    priority: Priority.high,
  );
  await _notifications.show(
    999001,
    '💊 Test reminder',
    'Notifications are working. Your dose alarms will appear like this.',
    const NotificationDetails(android: androidDetails),
  );
}

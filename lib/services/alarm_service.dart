// lib/services/alarm_service.dart

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../models/alarm_log.dart';
import 'hive_service.dart';

class AlarmService {
  static const uuid = Uuid();

  /// Initialize alarm service
  static Future<void> init() async {
    try {
      await AwesomeNotifications().initialize(
        null, // Let awesome_notifications use default app icon
        [
          NotificationChannel(
            channelKey: 'alarm_channel',
            channelName: 'Medicine Alarms',
            channelDescription: 'Notification channel for medicine reminders',
            defaultColor: const Color(0xFF9D50DD),
            ledColor: Colors.white,
            importance: NotificationImportance.Max,
            channelShowBadge: true,
            locked: true, // Keep notification until user interacts
            defaultRingtoneType: DefaultRingtoneType.Alarm,
            criticalAlerts: true,
          ),
        ],
      );
      debugPrint('✅ Awesome Notifications initialized');
    } catch (e) {
      debugPrint('❌ Error initializing alarm service: $e');
      rethrow;
    }
  }

  /// Generate deterministic alarm ID from medicine ID
  static int generateAlarmId(String medicineId) {
    // Use hash code to generate a positive integer
    return medicineId.hashCode.abs() % 2147483647;
  }

  /// Schedule an alarm for a medicine
  static Future<void> scheduleAlarm(Medicine medicine) async {
    try {
      if (!medicine.isActive) {
        debugPrint(
          '⚠️ Medicine ${medicine.name} is not active, skipping alarm',
        );
        return;
      }

      final nextAlarmTime = _calculateNextAlarmTime(medicine);
      if (nextAlarmTime == null) {
        debugPrint('⚠️ No valid next alarm time for ${medicine.name}');
        return;
      }

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: medicine.alarmId,
          channelKey: 'alarm_channel',
          title: 'Medicine Reminder',
          body: 'Time to take ${medicine.name}',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          payload: {'medicineId': medicine.id},
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'TAKE',
            label: 'I TAKE',
            actionType: ActionType.SilentAction,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: 'LATER',
            actionType: ActionType.SilentAction,
          ),
        ],
        schedule: NotificationCalendar.fromDate(
          date: nextAlarmTime,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      debugPrint('✅ Alarm scheduled for ${medicine.name} at $nextAlarmTime');
    } catch (e) {
      debugPrint('❌ Error scheduling alarm for ${medicine.name}: $e');
      rethrow;
    }
  }

  /// Cancel an alarm
  static Future<void> cancelAlarm(int alarmId) async {
    try {
      await AwesomeNotifications().cancel(alarmId);
      debugPrint('✅ Alarm $alarmId cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling alarm $alarmId: $e');
      rethrow;
    }
  }

  /// Snooze an alarm
  static Future<void> snoozeAlarm(Medicine medicine, {int minutes = 5}) async {
    try {
      // Cancel current alarm
      await cancelAlarm(medicine.alarmId);

      // Schedule new alarm after specified minutes
      final snoozeTime = DateTime.now().add(Duration(minutes: minutes));

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: medicine.alarmId,
          channelKey: 'alarm_channel',
          title: 'Medicine Reminder (Snoozed)',
          body: 'Time to take ${medicine.name}',
          category: NotificationCategory.Alarm,
          wakeUpScreen: true,
          fullScreenIntent: true,
          autoDismissible: false,
          payload: {'medicineId': medicine.id},
        ),
        actionButtons: [
          NotificationActionButton(
            key: 'TAKE',
            label: 'I TAKE',
            actionType: ActionType.SilentAction,
          ),
          NotificationActionButton(
            key: 'SNOOZE',
            label: 'LATER',
            actionType: ActionType.SilentAction,
          ),
        ],
        schedule: NotificationCalendar.fromDate(
          date: snoozeTime,
          allowWhileIdle: true,
          preciseAlarm: true,
        ),
      );

      // Log snooze action
      final log = AlarmLog(
        id: uuid.v4(),
        medicineId: medicine.id,
        scheduledDateTime: DateTime.now(),
        status: 'snoozed',
        actualTakenTime: DateTime.now(),
      );
      await HiveService.addLog(log);

      debugPrint('✅ Alarm snoozed for ${medicine.name} until $snoozeTime');
    } catch (e) {
      debugPrint('❌ Error snoozing alarm: $e');
      rethrow;
    }
  }

  /// Reschedule repeating alarm after it fires
  static Future<void> rescheduleRepeating(Medicine medicine) async {
    try {
      // Cancel current alarm
      await cancelAlarm(medicine.alarmId);

      // Check if medicine is still active and within date range
      if (!medicine.isActive) {
        debugPrint(
          '⚠️ Medicine ${medicine.name} is not active, not rescheduling',
        );
        return;
      }

      final nextAlarmTime = _calculateNextAlarmTime(medicine);
      if (nextAlarmTime == null) {
        debugPrint('⚠️ No more alarms for ${medicine.name}, end date reached');
        // Deactivate medicine if end date reached
        medicine.isActive = false;
        await HiveService.updateMedicine(medicine);
        return;
      }

      // Schedule next alarm
      await scheduleAlarm(medicine);
      debugPrint('✅ Repeating alarm rescheduled for ${medicine.name}');
    } catch (e) {
      debugPrint('❌ Error rescheduling repeating alarm: $e');
      rethrow;
    }
  }

  /// Cancel all alarms
  static Future<void> cancelAllAlarms() async {
    try {
      await AwesomeNotifications().cancelAll();
      debugPrint('✅ All alarms cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all alarms: $e');
      rethrow;
    }
  }

  /// Check and reschedule all active alarms (call on app start)
  static Future<void> rescheduleAllActiveAlarms() async {
    try {
      final medicines = HiveService.getActiveMedicines();
      for (final medicine in medicines) {
        await scheduleAlarm(medicine);
      }
      debugPrint('✅ Rescheduled ${medicines.length} active alarms');
    } catch (e) {
      debugPrint('❌ Error rescheduling active alarms: $e');
    }
  }

  /// Mark medicine as taken
  static Future<void> markAsTaken(Medicine medicine) async {
    try {
      final now = DateTime.now();
      final log = AlarmLog(
        id: uuid.v4(),
        medicineId: medicine.id,
        scheduledDateTime: DateTime(
          now.year,
          now.month,
          now.day,
          medicine.hour,
          medicine.minute,
        ),
        status: 'taken',
        actualTakenTime: now,
      );
      await HiveService.addLog(log);

      // Stop the alarm
      await cancelAlarm(medicine.alarmId);

      // Reschedule for next occurrence
      await rescheduleRepeating(medicine);

      debugPrint('✅ Medicine ${medicine.name} marked as taken');
    } catch (e) {
      debugPrint('❌ Error marking medicine as taken: $e');
      rethrow;
    }
  }

  /// Mark medicine as missed
  static Future<void> markAsMissed(Medicine medicine) async {
    try {
      final now = DateTime.now();
      final log = AlarmLog(
        id: uuid.v4(),
        medicineId: medicine.id,
        scheduledDateTime: DateTime(
          now.year,
          now.month,
          now.day,
          medicine.hour,
          medicine.minute,
        ),
        status: 'missed',
        actualTakenTime: null,
      );
      await HiveService.addLog(log);

      // Stop the alarm
      await cancelAlarm(medicine.alarmId);

      // Reschedule for next occurrence
      await rescheduleRepeating(medicine);

      debugPrint('✅ Medicine ${medicine.name} marked as missed');
    } catch (e) {
      debugPrint('❌ Error marking medicine as missed: $e');
      rethrow;
    }
  }

  /// Calculate next alarm time for a medicine
  static DateTime? _calculateNextAlarmTime(Medicine medicine) {
    final now = DateTime.now();

    // Create time for today
    DateTime candidateTime = DateTime(
      now.year,
      now.month,
      now.day,
      medicine.hour,
      medicine.minute,
    );

    // If today's time has passed, start checking from tomorrow
    if (candidateTime.isBefore(now)) {
      candidateTime = candidateTime.add(const Duration(days: 1));
    }

    // Find next valid day (max 14 days ahead to avoid infinite loop)
    for (int i = 0; i < 14; i++) {
      final checkDate = candidateTime.add(Duration(days: i));

      // Check if within date range
      if (checkDate.isBefore(medicine.startDate)) {
        continue;
      }

      if (medicine.endDate != null) {
        final endOfDay = DateTime(
          medicine.endDate!.year,
          medicine.endDate!.month,
          medicine.endDate!.day,
          23,
          59,
          59,
        );
        if (checkDate.isAfter(endOfDay)) {
          return null; // Past end date
        }
      }

      // Check if scheduled for this day
      if (medicine.repeatType == 'daily') {
        return candidateTime.add(Duration(days: i));
      } else {
        // Custom days
        if (medicine.selectedDays.contains(checkDate.weekday)) {
          return candidateTime.add(Duration(days: i));
        }
      }
    }

    return null; // No valid alarm time found
  }
}

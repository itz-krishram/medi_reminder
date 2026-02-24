// lib/models/alarm_log.dart

import 'package:hive/hive.dart';

part 'alarm_log.g.dart';

@HiveType(typeId: 1)
class AlarmLog extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String medicineId;

  @HiveField(2)
  DateTime scheduledDateTime;

  @HiveField(3)
  String status; // 'taken' | 'missed' | 'snoozed'

  @HiveField(4)
  DateTime? actualTakenTime;

  AlarmLog({
    required this.id,
    required this.medicineId,
    required this.scheduledDateTime,
    required this.status,
    this.actualTakenTime,
  });

  /// Get status color based on status
  String get statusColor {
    switch (status) {
      case 'taken':
        return 'green';
      case 'missed':
        return 'red';
      case 'snoozed':
        return 'orange';
      default:
        return 'grey';
    }
  }

  /// Get display text for status
  String get statusDisplay {
    switch (status) {
      case 'taken':
        return 'Taken';
      case 'missed':
        return 'Missed';
      case 'snoozed':
        return 'Snoozed';
      default:
        return 'Unknown';
    }
  }

  /// Get formatted time string
  String get formattedScheduledTime {
    final hour = scheduledDateTime.hour;
    final minute = scheduledDateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourFormatted = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteFormatted = minute.toString().padLeft(2, '0');
    return '$hourFormatted:$minuteFormatted $period';
  }

  /// Create a copy with updated fields
  AlarmLog copyWith({
    String? id,
    String? medicineId,
    DateTime? scheduledDateTime,
    String? status,
    DateTime? actualTakenTime,
  }) {
    return AlarmLog(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      status: status ?? this.status,
      actualTakenTime: actualTakenTime ?? this.actualTakenTime,
    );
  }
}

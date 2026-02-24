// lib/models/medicine.dart

import 'package:hive/hive.dart';

part 'medicine.g.dart';

@HiveType(typeId: 0)
class Medicine extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int hour;

  @HiveField(3)
  int minute;

  @HiveField(4)
  String repeatType; // 'daily' | 'custom'

  @HiveField(5)
  List<int> selectedDays; // [1-7] where 1=Mon

  @HiveField(6)
  DateTime startDate;

  @HiveField(7)
  DateTime? endDate;

  @HiveField(8)
  bool isActive;

  @HiveField(9)
  int alarmId;

  Medicine({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    required this.repeatType,
    required this.selectedDays,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.alarmId,
  });

  /// Get formatted time string (e.g., "09:30 AM")
  String get formattedTime {
    final period = hour >= 12 ? 'PM' : 'AM';
    final hourFormatted = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteFormatted = minute.toString().padLeft(2, '0');
    return '$hourFormatted:$minuteFormatted $period';
  }

  /// Get readable repeat schedule
  String get repeatSchedule {
    if (repeatType == 'daily') {
      return 'Every day';
    } else {
      if (selectedDays.isEmpty) return 'Not scheduled';
      if (selectedDays.length == 7) return 'Every day';
      
      const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final days = selectedDays.map((d) => dayNames[d - 1]).join(', ');
      return days;
    }
  }

  /// Check if medicine is scheduled for a specific day
  bool isScheduledFor(DateTime date) {
    // Check if within date range
    if (date.isBefore(DateTime(startDate.year, startDate.month, startDate.day))) {
      return false;
    }
    if (endDate != null && date.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day))) {
      return false;
    }

    // Check repeat pattern
    if (repeatType == 'daily') {
      return true;
    } else {
      // Custom days: 1=Mon, 2=Tue, ..., 7=Sun
      // DateTime.weekday: 1=Mon, 2=Tue, ..., 7=Sun
      return selectedDays.contains(date.weekday);
    }
  }

  /// Create a copy with updated fields
  Medicine copyWith({
    String? id,
    String? name,
    int? hour,
    int? minute,
    String? repeatType,
    List<int>? selectedDays,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    int? alarmId,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatType: repeatType ?? this.repeatType,
      selectedDays: selectedDays ?? this.selectedDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      alarmId: alarmId ?? this.alarmId,
    );
  }
}

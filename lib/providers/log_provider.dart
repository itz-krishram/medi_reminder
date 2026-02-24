// lib/providers/log_provider.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alarm_log.dart';
import '../models/medicine.dart';
import '../services/hive_service.dart';

class LogProvider extends ChangeNotifier {
  List<AlarmLog> _logs = [];
  bool _isLoading = false;
  String? _error;

  List<AlarmLog> get logs => _logs;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all logs
  Future<void> loadLogs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _logs = HiveService.getAllLogs();
      // Sort by scheduled time (most recent first)
      _logs.sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Loaded ${_logs.length} logs');
    } catch (e) {
      _error = 'Failed to load logs: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Error loading logs: $e');
    }
  }

  /// Get logs for today
  List<AlarmLog> get todayLogs {
    return HiveService.getTodayLogs()
      ..sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
  }

  /// Get logs for last N days
  List<AlarmLog> getRecentLogs({int days = 7}) {
    return HiveService.getRecentLogs(days: days)
      ..sort((a, b) => b.scheduledDateTime.compareTo(a.scheduledDateTime));
  }

  /// Get logs grouped by date
  Map<String, List<AlarmLog>> getLogsGroupedByDate({int days = 7}) {
    final recentLogs = getRecentLogs(days: days);
    final grouped = <String, List<AlarmLog>>{};

    for (final log in recentLogs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.scheduledDateTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(log);
    }

    return grouped;
  }

  /// Get logs with medicine details
  List<LogWithMedicine> getLogsWithMedicineDetails({int days = 7}) {
    final recentLogs = getRecentLogs(days: days);
    final result = <LogWithMedicine>[];

    for (final log in recentLogs) {
      final medicine = HiveService.getMedicineById(log.medicineId);
      result.add(LogWithMedicine(log: log, medicine: medicine));
    }

    return result;
  }

  /// Get status for a medicine at a specific time
  String getMedicineStatus(Medicine medicine, DateTime date) {
    final scheduledTime = DateTime(
      date.year,
      date.month,
      date.day,
      medicine.hour,
      medicine.minute,
    );

    // Check if there's a log for this time
    final log = _logs.firstWhere(
      (l) =>
          l.medicineId == medicine.id &&
          l.scheduledDateTime.year == scheduledTime.year &&
          l.scheduledDateTime.month == scheduledTime.month &&
          l.scheduledDateTime.day == scheduledTime.day &&
          l.scheduledDateTime.hour == scheduledTime.hour &&
          l.scheduledDateTime.minute == scheduledTime.minute,
      orElse: () => AlarmLog(
        id: '',
        medicineId: '',
        scheduledDateTime: DateTime.now(),
        status: '',
      ),
    );

    if (log.id.isEmpty) {
      // No log exists - check if time has passed
      final now = DateTime.now();
      if (scheduledTime.isBefore(now)) {
        return 'missed';
      } else {
        return 'upcoming';
      }
    }

    return log.status;
  }

  /// Get statistics for a medicine
  MedicineStats getStatsForMedicine(String medicineId, {int days = 30}) {
    final medicineLogs = HiveService.getLogsForMedicine(medicineId);
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final relevantLogs = medicineLogs
        .where((log) => log.scheduledDateTime.isAfter(cutoffDate))
        .toList();

    final taken = relevantLogs.where((log) => log.status == 'taken').length;
    final missed = relevantLogs.where((log) => log.status == 'missed').length;
    final snoozed = relevantLogs.where((log) => log.status == 'snoozed').length;
    final total = relevantLogs.length;

    final adherenceRate = total > 0 ? (taken / total * 100).toStringAsFixed(1) : '0.0';

    return MedicineStats(
      taken: taken,
      missed: missed,
      snoozed: snoozed,
      total: total,
      adherenceRate: adherenceRate,
    );
  }

  /// Get overall statistics
  OverallStats getOverallStats({int days = 7}) {
    final recentLogs = getRecentLogs(days: days);
    
    final taken = recentLogs.where((log) => log.status == 'taken').length;
    final missed = recentLogs.where((log) => log.status == 'missed').length;
    final snoozed = recentLogs.where((log) => log.status == 'snoozed').length;
    final total = recentLogs.length;

    final adherenceRate = total > 0 ? (taken / total * 100).toStringAsFixed(1) : '0.0';

    return OverallStats(
      taken: taken,
      missed: missed,
      snoozed: snoozed,
      total: total,
      adherenceRate: adherenceRate,
      days: days,
    );
  }

  /// Clear old logs
  Future<void> clearOldLogs({int olderThanDays = 30}) async {
    try {
      await HiveService.deleteOldLogs(olderThanDays: olderThanDays);
      await loadLogs();
      debugPrint('✅ Old logs cleared');
    } catch (e) {
      _error = 'Failed to clear old logs: $e';
      notifyListeners();
      debugPrint('❌ Error clearing old logs: $e');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Helper class to combine log with medicine details
class LogWithMedicine {
  final AlarmLog log;
  final Medicine? medicine;

  LogWithMedicine({required this.log, required this.medicine});

  String get medicineName => medicine?.name ?? 'Unknown Medicine';
  String get formattedTime => log.formattedScheduledTime;
  String get status => log.status;
  String get statusDisplay => log.statusDisplay;
}

/// Statistics for a specific medicine
class MedicineStats {
  final int taken;
  final int missed;
  final int snoozed;
  final int total;
  final String adherenceRate;

  MedicineStats({
    required this.taken,
    required this.missed,
    required this.snoozed,
    required this.total,
    required this.adherenceRate,
  });
}

/// Overall statistics
class OverallStats {
  final int taken;
  final int missed;
  final int snoozed;
  final int total;
  final String adherenceRate;
  final int days;

  OverallStats({
    required this.taken,
    required this.missed,
    required this.snoozed,
    required this.total,
    required this.adherenceRate,
    required this.days,
  });
}

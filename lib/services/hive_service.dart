// lib/services/hive_service.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/medicine.dart';
import '../models/alarm_log.dart';

class HiveService {
  static const String medicinesBoxName = 'medicines';
  static const String logsBoxName = 'alarm_logs';

  static Box<Medicine>? _medicinesBox;
  static Box<AlarmLog>? _logsBox;

  /// Initialize Hive and register adapters
  static Future<void> init() async {
    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MedicineAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AlarmLogAdapter());
      }

      // Open boxes
      _medicinesBox = await Hive.openBox<Medicine>(medicinesBoxName);
      _logsBox = await Hive.openBox<AlarmLog>(logsBoxName);

      debugPrint('✅ Hive initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Hive: $e');
      rethrow;
    }
  }

  /// Get medicines box
  static Box<Medicine> get medicinesBox {
    if (_medicinesBox == null || !_medicinesBox!.isOpen) {
      throw Exception('Medicines box is not initialized');
    }
    return _medicinesBox!;
  }

  /// Get logs box
  static Box<AlarmLog> get logsBox {
    if (_logsBox == null || !_logsBox!.isOpen) {
      throw Exception('Logs box is not initialized');
    }
    return _logsBox!;
  }

  // ===== MEDICINE CRUD OPERATIONS =====

  /// Add a new medicine
  static Future<void> addMedicine(Medicine medicine) async {
    try {
      await medicinesBox.put(medicine.id, medicine);
      debugPrint('✅ Medicine added: ${medicine.name}');
    } catch (e) {
      debugPrint('❌ Error adding medicine: $e');
      rethrow;
    }
  }

  /// Get all medicines
  static List<Medicine> getAllMedicines() {
    try {
      return medicinesBox.values.toList();
    } catch (e) {
      debugPrint('❌ Error getting medicines: $e');
      return [];
    }
  }

  /// Get medicine by ID
  static Medicine? getMedicineById(String id) {
    try {
      return medicinesBox.get(id);
    } catch (e) {
      debugPrint('❌ Error getting medicine by ID: $e');
      return null;
    }
  }

  /// Update a medicine
  static Future<void> updateMedicine(Medicine medicine) async {
    try {
      await medicinesBox.put(medicine.id, medicine);
      debugPrint('✅ Medicine updated: ${medicine.name}');
    } catch (e) {
      debugPrint('❌ Error updating medicine: $e');
      rethrow;
    }
  }

  /// Delete a medicine
  static Future<void> deleteMedicine(String id) async {
    try {
      await medicinesBox.delete(id);
      debugPrint('✅ Medicine deleted: $id');
    } catch (e) {
      debugPrint('❌ Error deleting medicine: $e');
      rethrow;
    }
  }

  /// Get active medicines
  static List<Medicine> getActiveMedicines() {
    try {
      return medicinesBox.values.where((m) => m.isActive).toList();
    } catch (e) {
      debugPrint('❌ Error getting active medicines: $e');
      return [];
    }
  }

  /// Get medicines scheduled for a specific date
  static List<Medicine> getMedicinesForDate(DateTime date) {
    try {
      return medicinesBox.values
          .where((m) => m.isActive && m.isScheduledFor(date))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting medicines for date: $e');
      return [];
    }
  }

  // ===== ALARM LOG CRUD OPERATIONS =====

  /// Add a new log
  static Future<void> addLog(AlarmLog log) async {
    try {
      await logsBox.put(log.id, log);
      debugPrint('✅ Log added: ${log.status}');
    } catch (e) {
      debugPrint('❌ Error adding log: $e');
      rethrow;
    }
  }

  /// Get all logs
  static List<AlarmLog> getAllLogs() {
    try {
      return logsBox.values.toList();
    } catch (e) {
      debugPrint('❌ Error getting logs: $e');
      return [];
    }
  }

  /// Get log by ID
  static AlarmLog? getLogById(String id) {
    try {
      return logsBox.get(id);
    } catch (e) {
      debugPrint('❌ Error getting log by ID: $e');
      return null;
    }
  }

  /// Get logs for a specific medicine
  static List<AlarmLog> getLogsForMedicine(String medicineId) {
    try {
      return logsBox.values
          .where((log) => log.medicineId == medicineId)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting logs for medicine: $e');
      return [];
    }
  }

  /// Get logs for a date range
  static List<AlarmLog> getLogsForDateRange(DateTime start, DateTime end) {
    try {
      return logsBox.values
          .where((log) =>
              log.scheduledDateTime.isAfter(start.subtract(const Duration(days: 1))) &&
              log.scheduledDateTime.isBefore(end.add(const Duration(days: 1))))
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting logs for date range: $e');
      return [];
    }
  }

  /// Get logs for today
  static List<AlarmLog> getTodayLogs() {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));
      return getLogsForDateRange(today, tomorrow);
    } catch (e) {
      debugPrint('❌ Error getting today logs: $e');
      return [];
    }
  }

  /// Get logs for last N days
  static List<AlarmLog> getRecentLogs({int days = 7}) {
    try {
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDate = endDate.subtract(Duration(days: days));
      return getLogsForDateRange(startDate, endDate);
    } catch (e) {
      debugPrint('❌ Error getting recent logs: $e');
      return [];
    }
  }

  /// Check if a medicine was taken at a specific time
  static bool wasMedicineTaken(String medicineId, DateTime scheduledTime) {
    try {
      final logs = getLogsForMedicine(medicineId);
      return logs.any((log) =>
          log.status == 'taken' &&
          log.scheduledDateTime.year == scheduledTime.year &&
          log.scheduledDateTime.month == scheduledTime.month &&
          log.scheduledDateTime.day == scheduledTime.day &&
          log.scheduledDateTime.hour == scheduledTime.hour &&
          log.scheduledDateTime.minute == scheduledTime.minute);
    } catch (e) {
      debugPrint('❌ Error checking if medicine was taken: $e');
      return false;
    }
  }

  /// Delete old logs (older than specified days)
  static Future<void> deleteOldLogs({int olderThanDays = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: olderThanDays));
      final logsToDelete = logsBox.values
          .where((log) => log.scheduledDateTime.isBefore(cutoffDate))
          .map((log) => log.id)
          .toList();

      for (final id in logsToDelete) {
        await logsBox.delete(id);
      }
      debugPrint('✅ Deleted ${logsToDelete.length} old logs');
    } catch (e) {
      debugPrint('❌ Error deleting old logs: $e');
      rethrow;
    }
  }

  /// Close all boxes
  static Future<void> close() async {
    try {
      await _medicinesBox?.close();
      await _logsBox?.close();
      debugPrint('✅ Hive boxes closed');
    } catch (e) {
      debugPrint('❌ Error closing Hive boxes: $e');
    }
  }

  /// Clear all data (for testing purposes)
  static Future<void> clearAll() async {
    try {
      await medicinesBox.clear();
      await logsBox.clear();
      debugPrint('✅ All data cleared');
    } catch (e) {
      debugPrint('❌ Error clearing data: $e');
      rethrow;
    }
  }
}

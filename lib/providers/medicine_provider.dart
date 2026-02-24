// lib/providers/medicine_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/medicine.dart';
import '../services/hive_service.dart';
import '../services/alarm_service.dart';

class MedicineProvider extends ChangeNotifier {
  static const uuid = Uuid();
  
  List<Medicine> _medicines = [];
  bool _isLoading = false;
  String? _error;

  List<Medicine> get medicines => _medicines;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get medicines for today
  List<Medicine> get todayMedicines {
    final today = DateTime.now();
    return _medicines.where((m) => m.isActive && m.isScheduledFor(today)).toList()
      ..sort((a, b) {
        final aTime = a.hour * 60 + a.minute;
        final bTime = b.hour * 60 + b.minute;
        return aTime.compareTo(bTime);
      });
  }

  /// Get active medicines
  List<Medicine> get activeMedicines {
    return _medicines.where((m) => m.isActive).toList();
  }

  /// Initialize and load medicines
  Future<void> loadMedicines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medicines = HiveService.getAllMedicines();
      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Loaded ${_medicines.length} medicines');
    } catch (e) {
      _error = 'Failed to load medicines: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint('❌ Error loading medicines: $e');
    }
  }

  /// Add a new medicine
  Future<void> addMedicine({
    required String name,
    required int hour,
    required int minute,
    required String repeatType,
    required List<int> selectedDays,
    required DateTime startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    try {
      final id = uuid.v4();
      final alarmId = AlarmService.generateAlarmId(id);

      final medicine = Medicine(
        id: id,
        name: name.trim(),
        hour: hour,
        minute: minute,
        repeatType: repeatType,
        selectedDays: selectedDays,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
        alarmId: alarmId,
      );

      await HiveService.addMedicine(medicine);
      
      // Schedule alarm if active
      if (isActive) {
        await AlarmService.scheduleAlarm(medicine);
      }

      await loadMedicines();
      debugPrint('✅ Medicine added: $name');
    } catch (e) {
      _error = 'Failed to add medicine: $e';
      notifyListeners();
      debugPrint('❌ Error adding medicine: $e');
      rethrow;
    }
  }

  /// Update a medicine
  Future<void> updateMedicine(Medicine medicine) async {
    try {
      await HiveService.updateMedicine(medicine);
      
      // Cancel old alarm and schedule new one if active
      await AlarmService.cancelAlarm(medicine.alarmId);
      if (medicine.isActive) {
        await AlarmService.scheduleAlarm(medicine);
      }

      await loadMedicines();
      debugPrint('✅ Medicine updated: ${medicine.name}');
    } catch (e) {
      _error = 'Failed to update medicine: $e';
      notifyListeners();
      debugPrint('❌ Error updating medicine: $e');
      rethrow;
    }
  }

  /// Delete a medicine
  Future<void> deleteMedicine(String id) async {
    try {
      final medicine = HiveService.getMedicineById(id);
      if (medicine != null) {
        await AlarmService.cancelAlarm(medicine.alarmId);
        await HiveService.deleteMedicine(id);
        await loadMedicines();
        debugPrint('✅ Medicine deleted: ${medicine.name}');
      }
    } catch (e) {
      _error = 'Failed to delete medicine: $e';
      notifyListeners();
      debugPrint('❌ Error deleting medicine: $e');
      rethrow;
    }
  }

  /// Toggle medicine active status
  Future<void> toggleMedicineStatus(String id) async {
    try {
      final medicine = HiveService.getMedicineById(id);
      if (medicine != null) {
        final updatedMedicine = medicine.copyWith(isActive: !medicine.isActive);
        await updateMedicine(updatedMedicine);
      }
    } catch (e) {
      _error = 'Failed to toggle medicine status: $e';
      notifyListeners();
      debugPrint('❌ Error toggling medicine status: $e');
      rethrow;
    }
  }

  /// Get medicine by ID
  Medicine? getMedicineById(String id) {
    try {
      return _medicines.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check for duplicate medicines (same name and time)
  bool isDuplicate(String name, int hour, int minute, {String? excludeId}) {
    return _medicines.any((m) =>
        m.id != excludeId &&
        m.name.toLowerCase() == name.toLowerCase().trim() &&
        m.hour == hour &&
        m.minute == minute);
  }

  /// Refresh all alarms (useful after app restart)
  Future<void> refreshAlarms() async {
    try {
      await AlarmService.rescheduleAllActiveAlarms();
      debugPrint('✅ All alarms refreshed');
    } catch (e) {
      _error = 'Failed to refresh alarms: $e';
      notifyListeners();
      debugPrint('❌ Error refreshing alarms: $e');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

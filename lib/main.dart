// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'app.dart';
import 'providers/medicine_provider.dart';
import 'providers/log_provider.dart';
import 'services/hive_service.dart';
import 'services/alarm_service.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only for better UX)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive database
  debugPrint('🔧 Initializing Hive...');
  await HiveService.init();

  // Initialize Alarm service
  debugPrint('🔧 Initializing Alarm service...');
  await AlarmService.init();

  // Request necessary permissions
  debugPrint('🔧 Requesting permissions...');
  await requestPermissions();

  // Reschedule all active alarms (in case app was killed)
  debugPrint('🔧 Rescheduling active alarms...');
  await AlarmService.rescheduleAllActiveAlarms();

  debugPrint('✅ Initialization complete. Starting app...');

  // Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicineProvider()),
        ChangeNotifierProvider(create: (_) => LogProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

/// Request all necessary permissions for the app
Future<void> requestPermissions() async {
  try {
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    debugPrint('📱 Notification permission: $notificationStatus');

    // Request exact alarm permission (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      final alarmStatus = await Permission.scheduleExactAlarm.request();
      debugPrint('⏰ Exact alarm permission: $alarmStatus');
    }

    // Request ignore battery optimization (optional but recommended)
    final batteryStatus = await Permission.ignoreBatteryOptimizations.status;
    if (batteryStatus.isDenied) {
      debugPrint('🔋 Battery optimization not disabled (this is optional)');
    }

    // Check all permissions
    final permissions = {
      'Notification': await Permission.notification.status,
      'Exact Alarm': await Permission.scheduleExactAlarm.status,
      'Battery Optimization': await Permission.ignoreBatteryOptimizations.status,
    };

    permissions.forEach((name, status) {
      debugPrint('✓ $name: $status');
    });

    // Show warning if critical permissions denied
    if (!notificationStatus.isGranted) {
      debugPrint('⚠️ Warning: Notification permission denied. Alarms may not work properly.');
    }
  } catch (e) {
    debugPrint('❌ Error requesting permissions: $e');
  }
}

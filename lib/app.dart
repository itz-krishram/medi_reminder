// lib/app.dart

import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_trigger_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'services/hive_service.dart';
import 'models/medicine.dart';
import 'services/alarm_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotifications();
  }

  void _setupNotifications() {
    AwesomeNotifications().setListeners(
      onActionReceivedMethod: NotificationController.onActionReceivedMethod,
      onNotificationCreatedMethod:
          NotificationController.onNotificationCreatedMethod,
      onNotificationDisplayedMethod:
          NotificationController.onNotificationDisplayedMethod,
      onDismissActionReceivedMethod:
          NotificationController.onDismissActionReceivedMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: navigatorKey,
      home: const HomeScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/alarm') {
          final medicineId = settings.arguments as String?;
          if (medicineId != null) {
            return MaterialPageRoute(
              builder: (context) => AlarmTriggerScreen(medicineId: medicineId),
              fullscreenDialog: true,
            );
          }
        }
        return null;
      },
    );
  }
}

// Global navigator key for accessing navigator from outside widget tree
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotificationController {
  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    // Your code goes here
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('🔔 Alarm displayed: ${receivedNotification.id}');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    // Handling dismissing could mean missed or just dismissed
    debugPrint('Dismissed alarm: ${receivedAction.id}');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('Tap action received: ${receivedAction.buttonKeyPressed}');

    final medicineId = receivedAction.payload?['medicineId'];

    if (medicineId == null) return;

    final medicines = HiveService.getActiveMedicines();
    Medicine? triggeredMedicine;

    for (final medicine in medicines) {
      if (medicine.id == medicineId) {
        triggeredMedicine = medicine;
        break;
      }
    }

    if (triggeredMedicine == null) return;

    if (receivedAction.buttonKeyPressed == 'TAKE') {
      AlarmService.markAsTaken(triggeredMedicine);
    } else if (receivedAction.buttonKeyPressed == 'SNOOZE') {
      AlarmService.snoozeAlarm(triggeredMedicine);
    } else {
      // Tap on the notification body itself -> open full screen
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AlarmTriggerScreen(medicineId: medicineId),
          fullscreenDialog: true,
        ),
      );
    }
  }
}

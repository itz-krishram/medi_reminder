// lib/app.dart

import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'screens/home_screen.dart';
import 'screens/alarm_trigger_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupAlarmListener();
    _checkRingingAlarms();
  }

  Future<void> _checkRingingAlarms() async {
    final alarms = await Alarm.getAlarms();
    for (final alarm in alarms) {
      if (await Alarm.isRinging(alarm.id)) {
        _handleAlarmRing(alarm);
        break;
      }
    }
  }

  void _setupAlarmListener() {
    // Listen to alarm ring events
    Alarm.ringStream.stream.listen((alarmSettings) {
      _handleAlarmRing(alarmSettings);
    });
  }

  void _handleAlarmRing(AlarmSettings alarmSettings) {
    debugPrint('🔔 Alarm ringing: ${alarmSettings.id}');

    // Navigate to alarm trigger screen
    // We need to find the medicine ID from the alarm ID
    // For now, we'll pass the alarm ID and let the screen handle it

    // In a real scenario, you would store a mapping or include
    // the medicine ID in the notification body or use a custom data field
    // For this implementation, we'll navigate to a generic alarm screen

    Navigator.of(navigatorKey.currentContext!).push(
      MaterialPageRoute(
        builder: (context) => AlarmTriggerScreen(
          medicineId: alarmSettings.id
              .toString(), // This needs to be mapped properly
        ),
        fullscreenDialog: true,
      ),
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

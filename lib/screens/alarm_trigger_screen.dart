// lib/screens/alarm_trigger_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/medicine_provider.dart';
import '../providers/log_provider.dart';
import '../services/alarm_service.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class AlarmTriggerScreen extends StatefulWidget {
  final String medicineId;

  const AlarmTriggerScreen({super.key, required this.medicineId});

  @override
  State<AlarmTriggerScreen> createState() => _AlarmTriggerScreenState();
}

class _AlarmTriggerScreenState extends State<AlarmTriggerScreen>
    with SingleTickerProviderStateMixin {
  Timer? _autoDismissTimer;
  int _remainingSeconds = AppConstants.alarmAutoDismissMinutes * 60;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Medicine? _medicine;

  @override
  void initState() {
    super.initState();
    _loadMedicine();
    _startAutoDismissTimer();
    _setupAnimation();
    // Enter immersive fullscreen mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _loadMedicine() {
    final medicineProvider = Provider.of<MedicineProvider>(
      context,
      listen: false,
    );
    _medicine = medicineProvider.getMedicineById(widget.medicineId);
    if (_medicine == null) {
      // Medicine not found, close screen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _setupAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAutoDismissTimer() {
    _autoDismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          _handleMissed();
        }
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _pulseController.dispose();
    // Restore normal UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _handleTaken() async {
    if (_medicine == null) return;

    try {
      await AlarmService.markAsTaken(_medicine!);
      // Reload logs so history screen shows the update
      if (mounted) {
        await Provider.of<LogProvider>(context, listen: false).loadLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medicine marked as taken'),
            backgroundColor: AppColors.taken,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error marking medicine as taken: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSnooze() async {
    if (_medicine == null) return;

    try {
      await AlarmService.snoozeAlarm(
        _medicine!,
        minutes: AppConstants.snoozeDurationMinutes,
      );
      // Reload logs so history screen shows the update
      if (mounted) {
        await Provider.of<LogProvider>(context, listen: false).loadLogs();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Alarm snoozed for ${AppConstants.snoozeDurationMinutes} minutes',
            ),
            backgroundColor: AppColors.snoozed,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error snoozing alarm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleMissed() async {
    if (_medicine == null) return;

    try {
      await AlarmService.markAsMissed(_medicine!);
      // Reload logs so history screen shows the update
      if (mounted) {
        await Provider.of<LogProvider>(context, listen: false).loadLogs();
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error marking medicine as missed: $e');
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  String _getCurrentTime() {
    return DateFormat('hh:mm a').format(DateTime.now());
  }

  String _getAutoDismissText() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return 'Auto-dismiss in ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_medicine == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/app_logo.jpeg'),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(Colors.black87, BlendMode.darken),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Auto-dismiss timer
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Text(
                    _getAutoDismissText(),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),

                // Main Content
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Animated App Logo
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/app_logo.png',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppConstants.spacingLarge * 2),

                      // Medicine Name
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingLarge,
                        ),
                        child: Text(
                          _medicine!.name,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingMedium),

                      // Current Time
                      Text(
                        _getCurrentTime(),
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingMedium),

                      // Message
                      const Text(
                        'Time to take your medicine',
                        style: TextStyle(fontSize: 20, color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    children: [
                      // I Take Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: _handleTaken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.taken,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.check_circle, size: 28),
                          label: const Text(
                            'I TAKE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacingMedium),

                      // Later Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: OutlinedButton.icon(
                          onPressed: _handleSnooze,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          icon: const Icon(Icons.snooze, size: 28),
                          label: const Text(
                            'LATER',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

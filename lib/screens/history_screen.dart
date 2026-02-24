// lib/screens/history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/log_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/status_badge.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedDays = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine History'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.filter_list),
            onSelected: (days) {
              setState(() {
                _selectedDays = days;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 7,
                child: Text('Last 7 days'),
              ),
              const PopupMenuItem(
                value: 14,
                child: Text('Last 14 days'),
              ),
              const PopupMenuItem(
                value: 30,
                child: Text('Last 30 days'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<LogProvider>(
        builder: (context, logProvider, child) {
          if (logProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (logProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error.withOpacity(0.5),
                  ),
                  const SizedBox(height: AppConstants.spacingMedium),
                  Text(
                    'Error loading history',
                    style: AppTextStyles.titleMedium,
                  ),
                  const SizedBox(height: AppConstants.spacingSmall),
                  Text(
                    logProvider.error!,
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final logsWithMedicine = logProvider.getLogsWithMedicineDetails(days: _selectedDays);

          if (logsWithMedicine.isEmpty) {
            return _buildEmptyState();
          }

          // Group by date
          final groupedLogs = <String, List<LogWithMedicine>>{};
          for (final logWithMedicine in logsWithMedicine) {
            final dateKey = DateFormat('yyyy-MM-dd').format(logWithMedicine.log.scheduledDateTime);
            if (!groupedLogs.containsKey(dateKey)) {
              groupedLogs[dateKey] = [];
            }
            groupedLogs[dateKey]!.add(logWithMedicine);
          }

          // Sort dates (most recent first)
          final sortedDates = groupedLogs.keys.toList()
            ..sort((a, b) => b.compareTo(a));

          return Column(
            children: [
              // Statistics Card
              _buildStatsCard(logProvider),

              // History List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.paddingMedium,
                  ),
                  itemCount: sortedDates.length,
                  itemBuilder: (context, index) {
                    final dateKey = sortedDates[index];
                    final date = DateTime.parse(dateKey);
                    final logs = groupedLogs[dateKey]!;

                    return _buildDateSection(date, logs);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(LogProvider logProvider) {
    final stats = logProvider.getOverallStats(days: _selectedDays);

    return Container(
      margin: const EdgeInsets.all(AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        children: [
          Text(
            'Last $_selectedDays days',
            style: AppTextStyles.titleMedium.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Taken',
                stats.taken.toString(),
                Icons.check_circle,
                AppColors.taken,
              ),
              _buildStatItem(
                'Missed',
                stats.missed.toString(),
                Icons.cancel,
                AppColors.missed,
              ),
              _buildStatItem(
                'Snoozed',
                stats.snoozed.toString(),
                Icons.snooze,
                AppColors.snoozed,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMedium),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.show_chart, color: Colors.white, size: 20),
                const SizedBox(width: AppConstants.spacingSmall),
                Text(
                  'Adherence: ${stats.adherenceRate}%',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection(DateTime date, List<LogWithMedicine> logs) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    String dateLabel;
    if (dateOnly == today) {
      dateLabel = 'Today';
    } else if (dateOnly == yesterday) {
      dateLabel = 'Yesterday';
    } else {
      dateLabel = DateFormat('EEEE, MMM d').format(date);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.paddingMedium,
            vertical: AppConstants.paddingSmall,
          ),
          child: Text(
            dateLabel,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        ...logs.map((logWithMedicine) => _buildLogItem(logWithMedicine)),
        const SizedBox(height: AppConstants.spacingSmall),
      ],
    );
  }

  Widget _buildLogItem(LogWithMedicine logWithMedicine) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall / 2,
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.getStatusColor(logWithMedicine.status).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          ),
          child: Icon(
            Icons.medication,
            color: AppTheme.getStatusColor(logWithMedicine.status),
          ),
        ),
        title: Text(
          logWithMedicine.medicineName,
          style: AppTextStyles.titleSmall,
        ),
        subtitle: Text(
          logWithMedicine.formattedTime,
          style: AppTextStyles.bodySmall,
        ),
        trailing: StatusBadge(
          status: logWithMedicine.status,
          showIcon: true,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 120,
              color: AppColors.textDisabled.withOpacity(0.5),
            ),
            const SizedBox(height: AppConstants.spacingLarge),
            Text(
              'No history yet',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppConstants.spacingSmall),
            Text(
              'Your medicine history will appear here',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

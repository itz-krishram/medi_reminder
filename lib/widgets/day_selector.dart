// lib/widgets/day_selector.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DaySelector extends StatelessWidget {
  final List<int> selectedDays;
  final Function(List<int>) onDaysChanged;

  const DaySelector({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  void _toggleDay(int day) {
    final newSelectedDays = List<int>.from(selectedDays);
    if (newSelectedDays.contains(day)) {
      newSelectedDays.remove(day);
    } else {
      newSelectedDays.add(day);
    }
    newSelectedDays.sort();
    onDaysChanged(newSelectedDays);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Days',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppConstants.spacingSmall),
        Wrap(
          spacing: AppConstants.spacingSmall,
          runSpacing: AppConstants.spacingSmall,
          children: List.generate(7, (index) {
            final day = index + 1; // 1 = Monday, 7 = Sunday
            final isSelected = selectedDays.contains(day);
            
            return _DayChip(
              day: day,
              isSelected: isSelected,
              onTap: () => _toggleDay(day),
            );
          }),
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final int day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  String get dayName => AppConstants.dayNames[day - 1];

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: AnimatedContainer(
        duration: AppConstants.animationShort,
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingMedium,
          vertical: AppConstants.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          dayName,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

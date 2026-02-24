// lib/widgets/medicine_card.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../providers/log_provider.dart';
import '../utils/constants.dart';
import 'status_badge.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;

  const MedicineCard({
    super.key,
    required this.medicine,
    this.onTap,
    this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final logProvider = Provider.of<LogProvider>(context, listen: false);
    final status = logProvider.getMedicineStatus(medicine, DateTime.now());

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Medicine Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: AppColors.primary,
                      size: AppConstants.iconSizeMedium,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMedium),
                  
                  // Medicine Name and Time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: AppTextStyles.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          medicine.formattedTime,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Status Badge
                  StatusBadge(status: status),
                ],
              ),

              const SizedBox(height: AppConstants.spacingMedium),

              // Repeat Schedule
              Row(
                children: [
                  Icon(
                    Icons.repeat,
                    size: AppConstants.iconSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppConstants.spacingSmall),
                  Expanded(
                    child: Text(
                      medicine.repeatSchedule,
                      style: AppTextStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Active Status
              if (!medicine.isActive) ...[
                const SizedBox(height: AppConstants.spacingSmall),
                Row(
                  children: [
                    Icon(
                      Icons.pause_circle_outline,
                      size: AppConstants.iconSizeSmall,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppConstants.spacingSmall),
                    Text(
                      'Inactive',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],

              // Action Buttons
              if (onDelete != null || onToggle != null) ...[
                const SizedBox(height: AppConstants.spacingMedium),
                const Divider(height: 1),
                const SizedBox(height: AppConstants.spacingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onToggle != null)
                      TextButton.icon(
                        onPressed: onToggle,
                        icon: Icon(
                          medicine.isActive ? Icons.pause : Icons.play_arrow,
                          size: AppConstants.iconSizeSmall,
                        ),
                        label: Text(medicine.isActive ? 'Pause' : 'Resume'),
                      ),
                    if (onDelete != null)
                      TextButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          size: AppConstants.iconSizeSmall,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'Delete',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

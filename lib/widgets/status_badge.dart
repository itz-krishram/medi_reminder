// lib/widgets/status_badge.dart

import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.compact = false,
  });

  String get _statusText {
    switch (status) {
      case AppConstants.statusTaken:
        return 'Taken';
      case AppConstants.statusMissed:
        return 'Missed';
      case AppConstants.statusSnoozed:
        return 'Snoozed';
      case AppConstants.statusUpcoming:
        return 'Upcoming';
      default:
        return status;
    }
  }

  Color get _statusColor {
    return AppTheme.getStatusColor(status);
  }

  IconData get _statusIcon {
    return AppTheme.getStatusIcon(status);
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactBadge();
    } else {
      return _buildFullBadge();
    }
  }

  Widget _buildFullBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: showIcon ? AppConstants.paddingSmall : AppConstants.paddingMedium,
        vertical: AppConstants.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: _statusColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              _statusIcon,
              size: AppConstants.iconSizeSmall,
              color: _statusColor,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _statusText,
            style: AppTextStyles.labelSmall.copyWith(
              color: _statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBadge() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _statusColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _statusIcon,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

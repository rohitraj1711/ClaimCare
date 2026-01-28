import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Status badge widget for displaying claim status.
/// Uses color-coded backgrounds based on status.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool large;

  const StatusBadge({
    super.key,
    required this.status,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.getStatusColor(status);
    final bgColor = AppColors.getStatusBackgroundColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 16 : 12,
        vertical: large ? 8 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(large ? 8 : 16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: large ? 14 : 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'Draft';
      case 'SUBMITTED':
        return 'Submitted';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'PARTIALLY_SETTLED':
        return 'Partially Settled';
      default:
        return status;
    }
  }
}

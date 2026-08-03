import 'package:flutter/material.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';
import 'package:amar_dokan/features/report/data/models/report_period.dart';

/// PeriodSelector - dropdown chip that lets the user pick the active period.
///
/// Pure UI widget; callbacks bubble up via [onChanged]. The parent provider
/// stores the actual [ReportPeriod] state.
class PeriodSelector extends StatelessWidget {
  final ReportPeriodType selectedType;
  final ValueChanged<ReportPeriodType> onChanged;
  final VoidCallback onCustomRangeTap;

  const PeriodSelector({
    super.key,
    required this.selectedType,
    required this.onChanged,
    required this.onCustomRangeTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          for (final type in ReportPeriodType.values) ...[
            _Chip(
              label: _labelFor(type),
              isSelected: selectedType == type,
              onTap: type == ReportPeriodType.custom
                  ? onCustomRangeTap
                  : () => onChanged(type),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  String _labelFor(ReportPeriodType type) {
    switch (type) {
      case ReportPeriodType.today:
        return 'Today';
      case ReportPeriodType.yesterday:
        return 'Yesterday';
      case ReportPeriodType.thisWeek:
        return 'This Week';
      case ReportPeriodType.lastWeek:
        return 'Last Week';
      case ReportPeriodType.last7Days:
        return 'Last 7 Days';
      case ReportPeriodType.last30Days:
        return 'Last 30 Days';
      case ReportPeriodType.thisMonth:
        return 'This Month';
      case ReportPeriodType.lastMonth:
        return 'Last Month';
      case ReportPeriodType.thisYear:
        return 'This Year';
      case ReportPeriodType.lastYear:
        return 'Last Year';
      case ReportPeriodType.custom:
        return 'Custom';
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
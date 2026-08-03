import 'package:flutter/material.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';

/// KpiCard - a compact metric tile used on the Report overview tab.
///
/// Designed to be flexible:
/// - [color] drives the icon circle background and accent strip
/// - [icon] is optional — pass null to show a colored dot instead
/// - [subtitle] is a small grey caption below the value
/// - [trend] (optional) shows ▲ +X% or ▼ -X% in green/red
class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color color;
  final String? subtitle;
  final double? trend; // percent, positive = good
  final VoidCallback? onTap;

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.subtitle,
    this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final trendWidget = _buildTrend();

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: icon != null
                        ? Icon(icon, color: color, size: 22)
                        : Center(
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                  ),
                  const Spacer(),
                  if (trendWidget != null) trendWidget,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget? _buildTrend() {
    if (trend == null) return null;
    final isPositive = trend! >= 0;
    final trendColor = trend == 0
        ? AppColors.textSecondary
        : (isPositive ? AppColors.success : AppColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: trendColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
            color: trendColor,
            size: 16,
          ),
          Text(
            '${trend!.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
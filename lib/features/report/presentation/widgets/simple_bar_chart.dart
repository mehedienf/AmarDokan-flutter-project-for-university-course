import 'package:flutter/material.dart';

import 'package:amar_dokan/core/constants/app_colors.dart';

/// SimpleBarChart - a lightweight vertical bar chart built with [Container]s.
///
/// Takes a list of numeric [dataPoints] (with optional labels) and renders
/// them as proportional bars inside a fixed-height container. We avoid
/// external chart libraries to keep the build lean — this widget is good
/// enough for daily sales / daily profit / category comparison.
class SimpleBarChart extends StatelessWidget {
  final List<ChartPoint> dataPoints;
  final Color barColor;
  final Color axisColor;
  final double height;
  final bool showValues;
  final String? emptyMessage;

  const SimpleBarChart({
    super.key,
    required this.dataPoints,
    this.barColor = AppColors.primary,
    this.axisColor = AppColors.divider,
    this.height = 180,
    this.showValues = true,
    this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (dataPoints.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            emptyMessage ?? 'No data available',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final maxValue = dataPoints
        .map((p) => p.value)
        .fold<double>(0, (m, v) => v > m ? v : m);

    // Avoid divide-by-zero when all values are 0.
    final scale = maxValue == 0 ? 1.0 : maxValue;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Bars area — flex: 1 so labels get their own space.
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final p in dataPoints) ...[
                      Expanded(
                        child: _Bar(
                          value: p.value,
                          maxValue: scale,
                          color: barColor,
                          showValue: showValues,
                          tooltipLabel: p.tooltipValue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Axis line.
              Container(height: 1, color: axisColor),
              const SizedBox(height: 6),
              // X-axis labels.
              Row(
                children: [
                  for (final p in dataPoints)
                    Expanded(
                      child: Center(
                        child: Text(
                          p.label,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double value;
  final double maxValue;
  final Color color;
  final bool showValue;
  final String tooltipLabel;

  const _Bar({
    required this.value,
    required this.maxValue,
    required this.color,
    required this.showValue,
    required this.tooltipLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxValue == 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showValue && value > 0)
            Text(
              _shortValue(value),
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Tooltip(
                message: tooltipLabel,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: ratio * double.infinity,
                  constraints: BoxConstraints(
                    // Fallback when Expanded doesn't pass maxHeight — use 0
                    // and rely on the parent's Expanded to size us.
                    minHeight: ratio > 0 ? 4 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: ratio == 0
                        ? AppColors.divider
                        : color.withValues(alpha: 0.85),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortValue(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

/// Single bar entry.
class ChartPoint {
  final String label;
  final double value;
  final String tooltipValue;

  const ChartPoint({
    required this.label,
    required this.value,
    required this.tooltipValue,
  });
}
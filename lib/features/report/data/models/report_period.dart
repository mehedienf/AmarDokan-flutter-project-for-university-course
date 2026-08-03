/// ReportPeriod - Predefined date range presets used by the Report feature.
///
/// All presets are computed relative to DateTime.now() so they always
/// reflect the current day. For arbitrary ranges, use [ReportPeriodType.custom].
class ReportPeriod {
  final ReportPeriodType type;
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  const ReportPeriod({
    required this.type,
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  /// Number of days covered by the period (inclusive).
  int get dayCount {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    return end.difference(start).inDays + 1;
  }

  /// Build a preset based on [type] at the time of the call.
  factory ReportPeriod.fromType(ReportPeriodType type, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    switch (type) {
      case ReportPeriodType.today:
        final start = DateTime(clock.year, clock.month, clock.day);
        final end = DateTime(clock.year, clock.month, clock.day, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'Today',
          startDate: start,
          endDate: end,
        );

      case ReportPeriodType.yesterday:
        final yesterday = clock.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final end =
            DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'Yesterday',
          startDate: start,
          endDate: end,
        );

      case ReportPeriodType.thisWeek:
        // Monday → Sunday week.
        final daysFromMonday = (clock.weekday - DateTime.monday) % 7;
        final monday = DateTime(clock.year, clock.month, clock.day)
            .subtract(Duration(days: daysFromMonday));
        final sunday = monday.add(const Duration(days: 6));
        return ReportPeriod(
          type: type,
          label: 'This Week',
          startDate: monday,
          endDate: DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59),
        );

      case ReportPeriodType.lastWeek:
        final daysFromMonday = (clock.weekday - DateTime.monday) % 7;
        final thisMonday = DateTime(clock.year, clock.month, clock.day)
            .subtract(Duration(days: daysFromMonday));
        final lastMonday = thisMonday.subtract(const Duration(days: 7));
        final lastSunday = thisMonday.subtract(const Duration(seconds: 1));
        return ReportPeriod(
          type: type,
          label: 'Last Week',
          startDate: lastMonday,
          endDate: lastSunday,
        );

      case ReportPeriodType.thisMonth:
        final start = DateTime(clock.year, clock.month, 1);
        final lastDay =
            DateTime(clock.year, clock.month + 1, 1).subtract(const Duration(
          seconds: 1,
        ));
        return ReportPeriod(
          type: type,
          label: 'This Month',
          startDate: start,
          endDate: lastDay,
        );

      case ReportPeriodType.lastMonth:
        final thisMonthStart = DateTime(clock.year, clock.month, 1);
        final lastMonthStart = DateTime(clock.year, clock.month - 1, 1);
        final lastMonthEnd = thisMonthStart.subtract(const Duration(seconds: 1));
        return ReportPeriod(
          type: type,
          label: 'Last Month',
          startDate: lastMonthStart,
          endDate: lastMonthEnd,
        );

      case ReportPeriodType.last7Days:
        final start = DateTime(clock.year, clock.month, clock.day)
            .subtract(const Duration(days: 6));
        final end = DateTime(clock.year, clock.month, clock.day, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'Last 7 Days',
          startDate: start,
          endDate: end,
        );

      case ReportPeriodType.last30Days:
        final start = DateTime(clock.year, clock.month, clock.day)
            .subtract(const Duration(days: 29));
        final end = DateTime(clock.year, clock.month, clock.day, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'Last 30 Days',
          startDate: start,
          endDate: end,
        );

      case ReportPeriodType.thisYear:
        final start = DateTime(clock.year, 1, 1);
        final end = DateTime(clock.year, 12, 31, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'This Year',
          startDate: start,
          endDate: end,
        );

      case ReportPeriodType.lastYear:
        final start = DateTime(clock.year - 1, 1, 1);
        final end = DateTime(clock.year - 1, 12, 31, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'Last Year',
          startDate: start,
          endDate: end,
        );

      case ReportPeriodType.custom:
        // Sensible defaults — caller is expected to override.
        final start = DateTime(clock.year, clock.month, 1);
        final end = DateTime(clock.year, clock.month, clock.day, 23, 59, 59);
        return ReportPeriod(
          type: type,
          label: 'Custom Range',
          startDate: start,
          endDate: end,
        );
    }
  }

  ReportPeriod copyWith({
    ReportPeriodType? type,
    String? label,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return ReportPeriod(
      type: type ?? this.type,
      label: label ?? this.label,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  bool contains(DateTime value) =>
      !value.isBefore(startDate) && !value.isAfter(endDate);

  @override
  String toString() =>
      'ReportPeriod($type, $startDate → $endDate)';
}

enum ReportPeriodType {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last7Days,
  last30Days,
  thisYear,
  lastYear,
  custom,
}

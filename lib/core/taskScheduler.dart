import '../models/repeatRule.dart';
import '../models/rules/monthWeekRule.dart';
import '../models/task.dart';

class TaskScheduler {
  static bool shouldShowTask(
    Task task,
    RepeatRule? rule,
    DateTime date,
  ) {
    final target = _normalize(date);

    final anchor = _normalize(
      task.startDate != null
          ? DateTime.fromMillisecondsSinceEpoch(task.startDate!)
          : DateTime.fromMillisecondsSinceEpoch(task.createdAt),
    );

    if (target.isBefore(anchor)) {
      return false;
    }

    if (task.endDate != null) {
      final end = _normalize(DateTime.fromMillisecondsSinceEpoch(task.endDate!));
      if (target.isAfter(end)) {
        return false;
      }
    }

    if (rule == null || rule.repeatType == null || rule.repeatType!.isEmpty) {
      if (task.endDate != null) {
        final end = _normalize(DateTime.fromMillisecondsSinceEpoch(task.endDate!));
        return !target.isBefore(anchor) && !target.isAfter(end);
      }
      return _isSameDay(anchor, target);
    }

    final interval = (rule.interval == null || rule.interval! <= 0) ? 1 : rule.interval!;

    switch (rule.repeatType) {
      case 'daily':
        return _daily(anchor, target, interval);
      case 'weekly':
        return _weekly(anchor, target, rule, interval);
      case 'monthly_day':
        return _monthlyDay(anchor, target, rule, interval);
      case 'monthly_week':
        return _monthlyWeek(anchor, target, rule, interval);
      case 'yearly':
        return _yearly(anchor, target, rule, interval);
      case 'workday':
        return _workday(anchor, target, interval);
      default:
        return false;
    }
  }

  static bool _daily(DateTime anchor, DateTime date, int interval) {
    final diff = date.difference(anchor).inDays;
    return diff >= 0 && diff % interval == 0;
  }

  static bool _weekly(DateTime anchor, DateTime date, RepeatRule rule, int interval) {
    final weekDays = (rule.weekDays == null || rule.weekDays!.isEmpty)
        ? [anchor.weekday]
        : rule.weekDays!;

    if (!weekDays.contains(date.weekday)) {
      return false;
    }

    final anchorWeekStart = anchor.subtract(Duration(days: anchor.weekday - 1));
    final dateWeekStart = date.subtract(Duration(days: date.weekday - 1));
    final weekDiff = dateWeekStart.difference(anchorWeekStart).inDays ~/ 7;

    return weekDiff >= 0 && weekDiff % interval == 0;
  }

  static bool _monthlyDay(DateTime anchor, DateTime date, RepeatRule rule, int interval) {
    if (!_matchIntervalByMonth(anchor, date, interval)) {
      return false;
    }

    final monthDays = (rule.monthDays == null || rule.monthDays!.isEmpty)
        ? [anchor.day]
        : rule.monthDays!;

    return monthDays.contains(date.day);
  }

  static bool _monthlyWeek(DateTime anchor, DateTime date, RepeatRule rule, int interval) {
    if (!_matchIntervalByMonth(anchor, date, interval)) {
      return false;
    }

    if (rule.monthWeeks == null || rule.monthWeeks!.isEmpty) {
      return false;
    }

    final weekOfMonth = _getWeekOfMonth(date);

    for (final MonthWeekRule item in rule.monthWeeks!) {
      if (item.week == weekOfMonth && item.weekday == date.weekday) {
        return true;
      }
    }

    return false;
  }

  static bool _yearly(DateTime anchor, DateTime date, RepeatRule rule, int interval) {
    final yearDiff = date.year - anchor.year;
    if (yearDiff < 0 || yearDiff % interval != 0) {
      return false;
    }

    final list = (rule.yearDays == null || rule.yearDays!.isEmpty)
        ? ['${anchor.month.toString().padLeft(2, '0')}-${anchor.day.toString().padLeft(2, '0')}']
        : rule.yearDays!;

    final current = '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    return list.contains(current);
  }

  static bool _workday(DateTime anchor, DateTime date, int interval) {
    if (date.weekday < DateTime.monday || date.weekday > DateTime.friday) {
      return false;
    }

    if (interval <= 1) {
      return true;
    }

    final count = _countWorkdays(anchor, date);
    return count >= 0 && count % interval == 0;
  }

  static int _countWorkdays(DateTime start, DateTime end) {
    if (end.isBefore(start)) {
      return -1;
    }

    int count = 0;
    DateTime cursor = start;

    while (!cursor.isAfter(end)) {
      if (cursor.weekday >= DateTime.monday && cursor.weekday <= DateTime.friday) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return count - 1;
  }

  static bool _matchIntervalByMonth(DateTime anchor, DateTime date, int interval) {
    final monthDiff = (date.year - anchor.year) * 12 + (date.month - anchor.month);
    return monthDiff >= 0 && monthDiff % interval == 0;
  }

  static DateTime _normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static int _getWeekOfMonth(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final weekdayOffset = firstDay.weekday - 1;
    return ((date.day + weekdayOffset - 1) ~/ 7) + 1;
  }
}

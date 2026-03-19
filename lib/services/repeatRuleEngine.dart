import '../models/repeatRule.dart';

class RepeatRuleEngine {

  /// 判断指定日期是否符合周期规则
  ///
  /// 参数：
  /// rule - 周期规则
  /// date - 需要判断的日期
  ///
  /// 返回：
  /// true -> 该任务在这一天应该出现
  /// false -> 不出现
  static bool isMatch(RepeatRule rule, DateTime date) {

    switch (rule.repeatType) {

      case "daily":
        return _matchDaily(rule, date);

      case "weekly":
        return _matchWeekly(rule, date);

      case "monthly":
        return _matchMonthly(rule, date);

      case "yearly":
        return _matchYearly(rule, date);

      case "workday":
        return _matchWorkday(date);

      default:
        return false;
    }

  }

  /// 每天
  static bool _matchDaily(RepeatRule rule, DateTime date) {

    // interval 表示每N天
    if (rule.interval == null || rule.interval == 1) {
      return true;
    }

    return true;
  }

  /// 每周几
  static bool _matchWeekly(RepeatRule rule, DateTime date) {

    if (rule.weekDays == null) return false;

    int weekday = date.weekday; // 1-7

    return rule.weekDays!.contains(weekday);
  }

  /// 每月几号
  static bool _matchMonthly(RepeatRule rule, DateTime date) {

    if (rule.monthDays != null) {

      return rule.monthDays!.contains(date.day);

    }

    if (rule.monthWeeks != null) {

      return _matchMonthWeek(rule, date);

    }

    return false;
  }

  /// 每月第几个周几
  static bool _matchMonthWeek(RepeatRule rule, DateTime date) {

    int weekday = date.weekday;

    int weekOfMonth = ((date.day - 1) / 7).floor() + 1;

    for (var item in rule.monthWeeks!) {

      if (item.week == weekOfMonth &&
          item.weekday == weekday) {

        return true;
      }

    }

    return false;
  }

  /// 每年几号
  static bool _matchYearly(RepeatRule rule, DateTime date) {

    if (rule.yearDays == null) return false;

    String key = "${date.month}-${date.day}";

    return rule.yearDays!.contains(key);
  }

  /// 工作日
  static bool _matchWorkday(DateTime date) {

    return date.weekday >= 1 && date.weekday <= 5;

  }

}

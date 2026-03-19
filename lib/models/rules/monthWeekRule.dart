class MonthWeekRule {

  /// 第几周
  final int week;

  /// 星期几
  final int weekday;

  MonthWeekRule({
    required this.week,
    required this.weekday,
  });

  Map<String, dynamic> toMap() {
    return {
      "week": week,
      "weekday": weekday,
    };
  }

  factory MonthWeekRule.fromMap(Map<String, dynamic> map) {
    return MonthWeekRule(
      week: map["week"],
      weekday: map["weekday"],
    );
  }
}
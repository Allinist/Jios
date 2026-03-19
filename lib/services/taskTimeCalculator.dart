class TaskTimeCalculator {

  /// 计算倒计时
  static Duration? getCountdown(int? endTimestamp) {

    if (endTimestamp == null) return null;

    DateTime end =
        DateTime.fromMillisecondsSinceEpoch(endTimestamp);

    return end.difference(DateTime.now());

  }

  /// 计算已开始时间
  static Duration? getElapsed(int? startTimestamp) {

    if (startTimestamp == null) return null;

    DateTime start =
        DateTime.fromMillisecondsSinceEpoch(startTimestamp);

    return DateTime.now().difference(start);

  }

  /// 判断任务是否进行中
  static bool isRunning(int? startTimestamp, int? endTimestamp) {

    DateTime now = DateTime.now();

    if (startTimestamp != null) {

      DateTime start =
          DateTime.fromMillisecondsSinceEpoch(startTimestamp);

      if (now.isBefore(start)) return false;

    }

    if (endTimestamp != null) {

      DateTime end =
          DateTime.fromMillisecondsSinceEpoch(endTimestamp);

      if (now.isAfter(end)) return false;

    }

    return true;

  }

}
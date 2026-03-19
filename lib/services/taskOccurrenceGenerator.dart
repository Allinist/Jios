import '../models/task.dart';
import '../models/repeatRule.dart';
import 'repeatRuleEngine.dart';

class TaskOccurrenceGenerator {

  /// 生成某一天的任务列表
  ///
  /// 参数：
  /// tasks - 所有任务
  /// rules - 周期规则map
  /// date - 指定日期
  ///
  /// 返回：
  /// 当天应该显示的任务
  static List<Task> generateTasksForDate(

      List<Task> tasks,
      Map<int, RepeatRule> rules,
      DateTime date) {

    List<Task> result = [];

    for (Task task in tasks) {

      /// 1 检查任务时间范围

      if (!_isTaskActive(task, date)) {
        continue;
      }

      /// 2 没有周期规则

      if (task.repeatRuleId == null) {

        if (_isSameDay(task.startDate, date)) {
          result.add(task);
        }

        continue;
      }

      /// 3 获取周期规则

      RepeatRule? rule = rules[task.repeatRuleId];

      if (rule == null) continue;

      /// 4 判断规则

      bool match = RepeatRuleEngine.isMatch(rule, date);

      if (match) {
        result.add(task);
      }

    }

    return result;

  }

  /// 判断任务是否在时间范围内
  static bool _isTaskActive(Task task, DateTime date) {

    if (task.startDate == null && task.endDate == null) {
      return true;
    }

    DateTime target = DateTime(date.year, date.month, date.day);

    if (task.startDate != null) {

      DateTime start =
          DateTime.fromMillisecondsSinceEpoch(task.startDate!);

      if (target.isBefore(start)) {
        return false;
      }

    }

    if (task.endDate != null) {

      DateTime end =
          DateTime.fromMillisecondsSinceEpoch(task.endDate!);

      if (target.isAfter(end)) {
        return false;
      }

    }

    return true;

  }

  /// 判断是否是同一天
  static bool _isSameDay(int? timestamp, DateTime date) {

    if (timestamp == null) return false;

    DateTime taskDate =
        DateTime.fromMillisecondsSinceEpoch(timestamp);

    return taskDate.year == date.year &&
        taskDate.month == date.month &&
        taskDate.day == date.day;

  }

}
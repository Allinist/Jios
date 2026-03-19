import '../database/taskRecord.dart';

class StatisticsEngine {

  /// 计算连续完成天数
  static int calculateStreak(List<TaskRecord> records) {

    records.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;

    DateTime today = DateTime.now();

    for (var record in records) {

      DateTime date =
          DateTime.fromMillisecondsSinceEpoch(record.date);

      int diff = today.difference(date).inDays;

      if (diff == streak) {

        streak++;

      } else {

        break;

      }

    }

    return streak;

  }

}
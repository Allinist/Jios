/// TaskRecord
///
/// 任务记录
///
/// 用于统计任务完成情况
///
/// 例如：
///
/// 背单词
/// 2025-03-01 完成
/// 2025-03-02 完成
///
/// 可用于统计：
///
/// 连续完成天数
/// 完成率
/// 累计时间

class TaskRecord {

  /// 主键
  int? id;

  /// 任务ID
  int taskId;

  /// 日期
  int date;

  /// 持续时间（分钟）
  int? duration;

  /// 状态
  /// completed skipped failed
  String? status;

  /// 创建时间
  int createdAt;

  TaskRecord({
    this.id,
    required this.taskId,
    required this.date,
    this.duration,
    this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {

    return {

      'id': id,

      'task_id': taskId,

      'date': date,

      'duration': duration,

      'status': status,

      'created_at': createdAt,
    };

  }

  factory TaskRecord.fromMap(Map<String, dynamic> map) {

    return TaskRecord(

      id: map['id'],

      taskId: map['task_id'],

      date: map['date'],

      duration: map['duration'],

      status: map['status'],

      createdAt: map['created_at'],
    );

  }

}
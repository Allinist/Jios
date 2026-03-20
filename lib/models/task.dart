class Task {
  int? id;
  String title;
  String? description;
  int? taskBookId;
  String? taskType;
  int? priority;
  String? status;
  int? startDate;
  int? endDate;
  int? expectedDuration;
  int? repeatRuleId;
  int createdAt;
  int updatedAt;
  int? color;
  int? timelineDisplayMask;
  String? timelineGranularity;
  int? notifyAtStart;
  int? notifyBeforeStartMinutes;
  int? notifyAtEnd;
  int? notifyBeforeEndMinutes;
  String? widgetDisplayScopes;

  Task({
    this.id,
    required this.title,
    this.description,
    this.taskBookId,
    this.taskType,
    this.priority,
    this.status,
    this.startDate,
    this.endDate,
    this.expectedDuration,
    this.repeatRuleId,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.timelineDisplayMask,
    this.timelineGranularity,
    this.notifyAtStart,
    this.notifyBeforeStartMinutes,
    this.notifyAtEnd,
    this.notifyBeforeEndMinutes,
    this.widgetDisplayScopes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'task_book_id': taskBookId,
      'task_type': taskType,
      'priority': priority,
      'status': status,
      'start_date': startDate,
      'end_date': endDate,
      'expected_duration': expectedDuration,
      'repeat_rule_id': repeatRuleId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'color': color,
      'timeline_display_mask': timelineDisplayMask,
      'timeline_granularity': timelineGranularity,
      'notify_at_start': notifyAtStart,
      'notify_before_start_minutes': notifyBeforeStartMinutes,
      'notify_at_end': notifyAtEnd,
      'notify_before_end_minutes': notifyBeforeEndMinutes,
      'widget_display_scopes': widgetDisplayScopes,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      taskBookId: map['task_book_id'],
      taskType: map['task_type'],
      priority: map['priority'],
      status: map['status'],
      startDate: map['start_date'],
      endDate: map['end_date'],
      expectedDuration: map['expected_duration'],
      repeatRuleId: map['repeat_rule_id'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
      color: map['color'],
      timelineDisplayMask: map['timeline_display_mask'],
      timelineGranularity: map['timeline_granularity'],
      notifyAtStart: map['notify_at_start'],
      notifyBeforeStartMinutes: map['notify_before_start_minutes'],
      notifyAtEnd: map['notify_at_end'],
      notifyBeforeEndMinutes: map['notify_before_end_minutes'],
      widgetDisplayScopes: map['widget_display_scopes'],
    );
  }
}

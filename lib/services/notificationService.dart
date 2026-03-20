import 'package:flutter/services.dart';

import '../models/task.dart';

class NotificationService {
  static const MethodChannel _channel = MethodChannel('task_notification');

  static Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('request_permission');
    } catch (_) {}
  }

  static Future<void> syncTaskNotifications(Task task) async {
    if (task.id == null) {
      return;
    }

    try {
      await _channel.invokeMethod('sync_task_notifications', {
        'task_id': task.id,
        'title': task.title,
        'status': task.status,
        'start_date': task.startDate,
        'end_date': task.endDate,
        'notify_at_start': task.notifyAtStart == 1,
        'notify_before_start_minutes': task.notifyBeforeStartMinutes,
        'notify_at_end': task.notifyAtEnd == 1,
        'notify_before_end_minutes': task.notifyBeforeEndMinutes,
      });
    } catch (_) {}
  }

  static Future<void> cancelTaskNotifications(int taskId) async {
    try {
      await _channel.invokeMethod('cancel_task_notifications', {
        'task_id': taskId,
      });
    } catch (_) {}
  }
}

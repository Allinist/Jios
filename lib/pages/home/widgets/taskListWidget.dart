import 'package:flutter/material.dart';

import '../../../core/taskScheduler.dart';
import '../../../database/dao/repeatRuleDao.dart';
import '../../../database/dao/taskDao.dart';
import '../../../models/repeatRule.dart';
import '../../../models/task.dart';
import '../../../pages/task/taskDetailPage.dart';
import '../../../services/notificationService.dart';
import '../../../services/widgetServices.dart';
import 'taskItemWidget.dart';

class TaskListWidget extends StatefulWidget {
  final DateTime date;
  final int? selectedTaskBookId;
  final VoidCallback? onTasksChanged;

  const TaskListWidget({
    super.key,
    required this.date,
    required this.selectedTaskBookId,
    this.onTasksChanged,
  });

  @override
  State<TaskListWidget> createState() => _TaskListWidgetState();
}

class _TaskListWidgetState extends State<TaskListWidget> {
  static const int _displayElapsed = 1;
  static const int _displayRemaining = 2;
  static const int _displayDuration = 4;
  static const int _displaySinceLast = 8;
  static const int _displayUntilNext = 16;

  List<Task> tasks = [];
  Map<int, RepeatRule?> _ruleMap = {};

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void didUpdateWidget(covariant TaskListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    final dateChanged = !_isSameDay(oldWidget.date, widget.date);
    final filterChanged = oldWidget.selectedTaskBookId != widget.selectedTaskBookId;

    if (dateChanged || filterChanged) {
      loadTasks();
    }
  }

  Future<void> loadTasks() async {
    final dao = TaskDao();
    final ruleDao = RepeatRuleDao();

    final allTasks = await dao.getAll();
    final List<Task> result = [];
    final Map<int, RepeatRule?> nextRuleMap = {};

    for (final task in allTasks) {
      if (widget.selectedTaskBookId != null && task.taskBookId != widget.selectedTaskBookId) {
        continue;
      }

      RepeatRule? rule;

      if (task.repeatRuleId != null) {
        final ruleId = task.repeatRuleId!;
        if (!nextRuleMap.containsKey(ruleId)) {
          nextRuleMap[ruleId] = await ruleDao.getById(ruleId);
        }
        rule = nextRuleMap[ruleId];
      }

      if (TaskScheduler.shouldShowTask(task, rule, widget.date)) {
        result.add(task);
      }
    }

    result.sort(_taskComparator);

    if (!mounted) return;

    setState(() {
      tasks = result;
      _ruleMap = nextRuleMap;
    });

    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();
    widget.onTasksChanged?.call();
  }

  int _taskComparator(Task a, Task b) {
    final aCompleted = a.status == 'completed';
    final bCompleted = b.status == 'completed';

    if (aCompleted != bCompleted) {
      return aCompleted ? 1 : -1;
    }

    final aEnd = a.endDate ?? 9223372036854775807;
    final bEnd = b.endDate ?? 9223372036854775807;

    if (aEnd != bEnd) {
      return aEnd.compareTo(bEnd);
    }

    return a.createdAt.compareTo(b.createdAt);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('这一天没有任务'),
      );
    }

    return RefreshIndicator(
      onRefresh: loadTasks,
      child: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];

          return TaskItemWidget(
            task: task,
            rightAlignedLines: _buildTimelineLines(task),
            onCompletedChanged: (value) async {
              final updated = Task(
                id: task.id,
                title: task.title,
                description: task.description,
                taskBookId: task.taskBookId,
                taskType: task.taskType,
                priority: task.priority,
                status: value ? 'completed' : 'active',
                startDate: task.startDate,
                endDate: task.endDate,
                expectedDuration: task.expectedDuration,
                repeatRuleId: task.repeatRuleId,
                createdAt: task.createdAt,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
                color: task.color,
                timelineDisplayMask: task.timelineDisplayMask,
                timelineGranularity: task.timelineGranularity,
                notifyAtStart: task.notifyAtStart,
                notifyBeforeStartMinutes: task.notifyBeforeStartMinutes,
                notifyAtEnd: task.notifyAtEnd,
                notifyBeforeEndMinutes: task.notifyBeforeEndMinutes,
                widgetDisplayScopes: task.widgetDisplayScopes,
                widgetInfoType: task.widgetInfoType,
              );

              await TaskDao().update(updated);
              await NotificationService.syncTaskNotifications(updated);
              await loadTasks();
            },
            onTap: () async {
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TaskDetailPage(task: task),
                ),
              );

              if (changed == true) {
                await loadTasks();
              }
            },
          );
        },
      ),
    );
  }

  List<String> _buildTimelineLines(Task task) {
    final lines = <String>[];
    final now = DateTime.now();

    final mask = task.timelineDisplayMask ?? (_displayElapsed | _displayRemaining | _displayDuration);
    final granularity = _parseGranularity(task.timelineGranularity);
    final rule = task.repeatRuleId == null ? null : _ruleMap[task.repeatRuleId!];

    if ((mask & _displayElapsed) != 0 && task.startDate != null) {
      final start = DateTime.fromMillisecondsSinceEpoch(task.startDate!);
      if (now.isAfter(start)) {
        lines.add('已开始${_formatDuration(now.difference(start), granularity)}');
      }
    }

    if ((mask & _displayRemaining) != 0 && task.endDate != null) {
      final end = DateTime.fromMillisecondsSinceEpoch(task.endDate!);
      if (end.isAfter(now)) {
        lines.add('剩余${_formatDuration(end.difference(now), granularity)}');
      }
    }

    if ((mask & _displayDuration) != 0 && task.expectedDuration != null && task.expectedDuration! > 0) {
      lines.add('持续${_formatHoursMinutes(task.expectedDuration!)}');
    }

    if ((mask & _displaySinceLast) != 0 && rule != null) {
      final previous = _findPreviousOccurrence(task, rule, now);
      if (previous != null) {
        lines.add('距上次${_formatDuration(now.difference(previous), granularity)}');
      }
    }

    if ((mask & _displayUntilNext) != 0 && rule != null) {
      final next = _findNextOccurrence(task, rule, now);
      if (next != null && next.isAfter(now)) {
        lines.add('距下次${_formatDuration(next.difference(now), granularity)}');
      }
    }

    return lines;
  }

  DateTime? _findPreviousOccurrence(Task task, RepeatRule rule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 1460; i++) {
      final day = today.subtract(Duration(days: i));
      if (TaskScheduler.shouldShowTask(task, rule, day)) {
        return day;
      }
    }
    return null;
  }

  DateTime? _findNextOccurrence(Task task, RepeatRule rule, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    for (int i = 1; i <= 1460; i++) {
      final day = today.add(Duration(days: i));
      if (TaskScheduler.shouldShowTask(task, rule, day)) {
        return day;
      }
    }
    return null;
  }

  List<String> _parseGranularity(String? text) {
    final defaults = ['day', 'hour'];
    if (text == null || text.trim().isEmpty) {
      return defaults;
    }

    final list = text
        .split(',')
        .map((e) => e.trim())
        .where((e) => ['year', 'month', 'day', 'hour', 'minute'].contains(e))
        .toList();

    return list.isEmpty ? defaults : list;
  }

  String _formatDuration(Duration duration, List<String> granularity) {
    int minutes = duration.inMinutes;

    final units = <String>[];
    final definitions = [
      ('year', 60 * 24 * 365, '年'),
      ('month', 60 * 24 * 30, '月'),
      ('day', 60 * 24, '天'),
      ('hour', 60, '小时'),
      ('minute', 1, '分钟'),
    ];

    for (final (key, value, label) in definitions) {
      if (!granularity.contains(key)) {
        continue;
      }

      final count = minutes ~/ value;
      minutes = minutes % value;

      if (count > 0 || (key == 'minute' && units.isEmpty)) {
        units.add('$count$label');
      }
    }

    if (units.isEmpty) {
      return '0分钟';
    }

    return units.join('');
  }

  String _formatHoursMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return '$hours小时 $remain分钟';
  }
}

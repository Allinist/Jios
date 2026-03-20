import 'package:flutter/material.dart';

import '../../core/taskScheduler.dart';
import '../../database/dao/repeatRuleDao.dart';
import '../../database/dao/taskBookDao.dart';
import '../../database/dao/taskDao.dart';
import '../../models/repeatRule.dart';
import '../../models/task.dart';
import '../../models/taskBook.dart';
import '../home/widgets/taskItemWidget.dart';
import '../task/taskDetailPage.dart';
import '../../services/notificationService.dart';
import '../../services/widgetServices.dart';
import 'taskBookEditPage.dart';

class TaskBookPage extends StatefulWidget {
  const TaskBookPage({super.key});

  @override
  State<TaskBookPage> createState() => _TaskBookPageState();
}

class _TaskBookPageState extends State<TaskBookPage> {
  static const int _displayElapsed = 1;
  static const int _displayRemaining = 2;
  static const int _displayDuration = 4;
  static const int _displaySinceLast = 8;
  static const int _displayUntilNext = 16;

  final TaskBookDao _taskBookDao = TaskBookDao();
  final TaskDao _taskDao = TaskDao();
  final RepeatRuleDao _ruleDao = RepeatRuleDao();

  List<TaskBook> _books = [];
  Map<int, List<Task>> _tasksByBookId = {};
  List<Task> _unassignedTasks = [];
  Map<int, RepeatRule?> _ruleMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _taskBookDao.ensureDefaultBooks();
    final books = await _taskBookDao.getAll();
    final tasks = await _taskDao.getAll();
    final Map<int, RepeatRule?> ruleMap = {};

    for (final task in tasks) {
      final ruleId = task.repeatRuleId;
      if (ruleId == null || ruleMap.containsKey(ruleId)) {
        continue;
      }
      ruleMap[ruleId] = await _ruleDao.getById(ruleId);
    }

    final validBookIds = books.map((e) => e.id).whereType<int>().toSet();

    final Map<int, List<Task>> byBook = {};
    final List<Task> unassigned = [];

    for (final task in tasks) {
      final taskBookId = task.taskBookId;

      if (taskBookId == null || !validBookIds.contains(taskBookId)) {
        unassigned.add(task);
        continue;
      }

      byBook.putIfAbsent(taskBookId, () => []);
      byBook[taskBookId]!.add(task);
    }

    for (final list in byBook.values) {
      list.sort(_taskComparator);
    }
    unassigned.sort(_taskComparator);

    if (!mounted) return;

    setState(() {
      _books = books;
      _tasksByBookId = byBook;
      _unassignedTasks = unassigned;
      _ruleMap = ruleMap;
    });
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

  Future<void> _openBookEditor({TaskBook? book}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskBookEditPage(book: book)),
    );

    if (changed == true) {
      await _loadData();
    }
  }

  Future<void> _openTaskDetail(Task task) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailPage(task: task)),
    );

    if (changed == true) {
      await WidgetService.syncWidgetData();
      await WidgetService.refreshWidget();
      await _loadData();
    }
  }

  Future<void> _createTaskForBook(int? taskBookId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailPage.create(initialTaskBookId: taskBookId),
      ),
    );

    if (changed == true) {
      await WidgetService.syncWidgetData();
      await WidgetService.refreshWidget();
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('任务本')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          key: const PageStorageKey<String>('taskbook_list_scroll'),
          children: [
            for (final book in _books)
              ExpansionTile(
                key: PageStorageKey<String>('taskbook_tile_${book.id ?? -1}'),
                title: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: () => _openBookEditor(book: book),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        if (book.color != null)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: Color(int.parse(book.color!)),
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(book.name),
                      ],
                    ),
                  ),
                ),
                subtitle: (book.description == null || book.description!.isEmpty)
                    ? null
                    : Text(book.description!),
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_task),
                    title: const Text('新增任务'),
                    onTap: () => _createTaskForBook(book.id),
                  ),
                  ..._buildTaskTiles(_tasksByBookId[book.id] ?? []),
                ],
              ),
            if (_unassignedTasks.isNotEmpty)
              ExpansionTile(
                key: const PageStorageKey<String>('taskbook_tile_unassigned'),
                initiallyExpanded: true,
                title: const Text('未归类任务'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_task),
                    title: const Text('新增任务'),
                    onTap: () => _createTaskForBook(null),
                  ),
                  ..._buildTaskTiles(_unassignedTasks),
                ],
              ),
            if (_books.isEmpty && _unassignedTasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('暂无任务本，点击右下角新增'),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'taskbook_add_fab',
        onPressed: () => _openBookEditor(),
        icon: const Icon(Icons.add),
        label: const Text('新增任务本'),
      ),
    );
  }

  List<Widget> _buildTaskTiles(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const [
        ListTile(
          title: Text('暂无任务'),
        ),
      ];
    }

    return tasks
        .map(
          (task) => TaskItemWidget(
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

              await _taskDao.update(updated);
              await NotificationService.syncTaskNotifications(updated);
              await WidgetService.syncWidgetData();
              await WidgetService.refreshWidget();
              await _loadData();
            },
            onTap: () => _openTaskDetail(task),
          ),
        )
        .toList();
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

    return units.isEmpty ? '0分钟' : units.join('');
  }

  String _formatHoursMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remain = minutes % 60;
    return '$hours小时 $remain分钟';
  }
}

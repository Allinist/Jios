import 'package:flutter/material.dart';

import '../../core/taskScheduler.dart';
import '../../database/dao/repeatRuleDao.dart';
import '../../database/dao/taskDao.dart';
import '../../models/repeatRule.dart';
import 'widgets/addTaskButton.dart';
import 'widgets/calendarWidget.dart';
import 'widgets/taskBookFilter.dart';
import 'widgets/taskListWidget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime selectedDate = DateTime.now();
  int? selectedTaskBookId;
  Map<String, List<Color>> _calendarDots = {};

  @override
  void initState() {
    super.initState();
    _loadCalendarDots();
  }

  Future<void> _loadCalendarDots() async {
    final taskDao = TaskDao();
    final ruleDao = RepeatRuleDao();

    final allTasks = await taskDao.getAll();

    final Map<int, RepeatRule?> ruleMap = {};
    for (final task in allTasks) {
      final ruleId = task.repeatRuleId;
      if (ruleId == null || ruleMap.containsKey(ruleId)) {
        continue;
      }
      ruleMap[ruleId] = await ruleDao.getById(ruleId);
    }

    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    final leading = firstDay.weekday % 7;
    final rangeStart = firstDay.subtract(Duration(days: leading));

    final Map<String, List<Color>> dots = {};

    for (int i = 0; i < 42; i++) {
      final day = DateTime(rangeStart.year, rangeStart.month, rangeStart.day + i);
      final colors = <Color>[];

      for (final task in allTasks) {
        if (task.status == 'completed') {
          continue;
        }

        if (selectedTaskBookId != null && task.taskBookId != selectedTaskBookId) {
          continue;
        }

        final rule = task.repeatRuleId == null ? null : ruleMap[task.repeatRuleId!];

        if (!TaskScheduler.shouldShowTask(task, rule, day)) {
          continue;
        }

        if (task.color == null) {
          continue;
        }

        final color = Color(task.color!);
        if (!colors.any((c) => c.toARGB32() == color.toARGB32())) {
          colors.add(color);
        }
      }

      if (colors.isNotEmpty) {
        dots[_keyOf(day)] = colors;
      }
    }

    if (!mounted) return;

    setState(() {
      _calendarDots = dots;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CalendarWidget(
              selectedDate: selectedDate,
              dateColorDots: _calendarDots,
              onDateSelected: (date) {
                setState(() {
                  selectedDate = date;
                });
                _loadCalendarDots();
              },
              onTodayTap: () {
                setState(() {
                  selectedDate = DateTime.now();
                });
                _loadCalendarDots();
              },
            ),
            TaskBookFilter(
              selectedTaskBookId: selectedTaskBookId,
              onChanged: (bookId) {
                setState(() {
                  selectedTaskBookId = bookId;
                });
                _loadCalendarDots();
              },
            ),
            Expanded(
              child: TaskListWidget(
                date: selectedDate,
                selectedTaskBookId: selectedTaskBookId,
                onTasksChanged: _loadCalendarDots,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const AddTaskButton(),
    );
  }

  String _keyOf(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

import 'package:flutter/material.dart';

import '../../database/dao/repeatRuleDao.dart';
import '../../database/dao/taskBookDao.dart';
import '../../database/dao/taskDao.dart';
import '../../models/repeatRule.dart';
import '../../models/task.dart';
import '../../models/taskBook.dart';
import '../../services/notificationService.dart';
import '../repeatRuleEditor/repeatRuleEditorPage.dart';
import '../taskBook/taskBookEditPage.dart';

class TaskDetailPage extends StatefulWidget {
  final Task? task;

  const TaskDetailPage({super.key, this.task});

  const TaskDetailPage.create({super.key}) : task = null;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  static const int _displayElapsed = 1;
  static const int _displayRemaining = 2;
  static const int _displayDuration = 4;
  static const int _displaySinceLast = 8;
  static const int _displayUntilNext = 16;

  static const List<String> _allGranularity = ['year', 'month', 'day', 'hour', 'minute'];

  final _taskDao = TaskDao();
  final _taskBookDao = TaskBookDao();
  final _repeatRuleDao = RepeatRuleDao();

  late bool _isCreate;

  int? _taskId;
  int? _repeatRuleId;

  String _title = '';
  String _description = '';
  int? _taskBookId;
  int? _color;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expectedDurationMinutes;
  bool _notifyAtStart = false;
  int? _notifyBeforeStartMinutes;
  bool _notifyAtEnd = false;
  int? _notifyBeforeEndMinutes;

  int _timelineDisplayMask = _displayElapsed | _displayRemaining | _displayDuration;
  List<String> _timelineGranularity = ['day', 'hour'];

  RepeatRule? _repeatRule;
  List<TaskBook> _books = [];

  @override
  void initState() {
    super.initState();
    _isCreate = widget.task == null;
    _initFromTask();
    _loadTaskBooks();
    _loadRepeatRule();
  }

  void _initFromTask() {
    final task = widget.task;
    if (task == null) return;

    _taskId = task.id;
    _repeatRuleId = task.repeatRuleId;
    _title = task.title;
    _description = task.description ?? '';
    _taskBookId = task.taskBookId;
    _color = task.color;
    _expectedDurationMinutes = task.expectedDuration;

    if (task.startDate != null) {
      _startDate = DateTime.fromMillisecondsSinceEpoch(task.startDate!);
    }
    if (task.endDate != null) {
      _endDate = DateTime.fromMillisecondsSinceEpoch(task.endDate!);
    }

    if (task.timelineDisplayMask != null) {
      _timelineDisplayMask = task.timelineDisplayMask!;
    }

    _notifyAtStart = task.notifyAtStart == 1;
    _notifyBeforeStartMinutes = task.notifyBeforeStartMinutes;
    _notifyAtEnd = task.notifyAtEnd == 1;
    _notifyBeforeEndMinutes = task.notifyBeforeEndMinutes;

    final granularityText = task.timelineGranularity;
    if (granularityText != null && granularityText.trim().isNotEmpty) {
      final list = granularityText
          .split(',')
          .map((e) => e.trim())
          .where((e) => _allGranularity.contains(e))
          .toList();

      if (list.isNotEmpty) {
        _timelineGranularity = list;
      }
    }
  }

  Future<void> _loadTaskBooks() async {
    await _taskBookDao.ensureDefaultBooks();
    final books = await _taskBookDao.getAll();

    if (!mounted) return;

    setState(() {
      _books = books;
    });
  }

  Future<void> _loadRepeatRule() async {
    if (_repeatRuleId == null) return;

    final rule = await _repeatRuleDao.getById(_repeatRuleId!);

    if (!mounted) return;

    setState(() {
      _repeatRule = rule;
    });
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: _title);
    final result = await _showTextEditDialog(title: '任务名称', controller: controller);
    if (result == null) return;

    setState(() {
      _title = result;
    });
  }

  Future<void> _editDescription() async {
    final controller = TextEditingController(text: _description);
    final result = await _showTextEditDialog(
      title: '任务描述',
      controller: controller,
      minLines: 3,
      maxLines: 6,
    );
    if (result == null) return;

    setState(() {
      _description = result;
    });
  }

  Future<String?> _showTextEditDialog({
    required String title,
    required TextEditingController controller,
    int minLines = 1,
    int maxLines = 1,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTaskBook() async {
    final selected = await showModalBottomSheet<int?>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('新建任务本'),
                onTap: () => Navigator.pop(context, -2),
              ),
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('移除任务本（未归类）'),
                onTap: () => Navigator.pop(context, -1),
              ),
              for (final book in _books)
                ListTile(
                  title: Text(book.name),
                  onTap: () => Navigator.pop(context, book.id),
                ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;

    if (selected == -2) {
      if (!mounted) return;
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const TaskBookEditPage()),
      );

      if (changed == true) {
        await _loadTaskBooks();
      }
      return;
    }

    setState(() {
      _taskBookId = selected == -1 ? null : selected;

      if (_color == null && _taskBookId != null) {
        String? bookColor;
        for (final book in _books) {
          if (book.id == _taskBookId) {
            bookColor = book.color;
            break;
          }
        }
        if (bookColor != null) {
          _color = int.tryParse(bookColor);
        }
      }
    });
  }

  Future<void> _pickColor() async {
    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.cyan,
      Colors.lime,
      Colors.pink,
      Colors.amber,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.deepPurple,
      Colors.grey,
      Colors.black,
    ];

    final picked = await showDialog<int?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors
              .map(
                (color) => GestureDetector(
                  onTap: () => Navigator.pop(context, color.toARGB32()),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: _color == color.toARGB32() ? 3 : 1,
                        color: _color == color.toARGB32() ? Colors.black : Colors.black26,
                      ),
                    ),
                  ),
                ),
              )
              .toList()
            ..insert(
              0,
              GestureDetector(
                onTap: () => Navigator.pop(context, -1),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: _color == null ? 3 : 1,
                      color: _color == null ? Colors.black : Colors.black26,
                    ),
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            ),
        ),
      ),
    );

    if (picked == null) return;

    setState(() {
      _color = picked == -1 ? null : picked;
    });
  }

  Future<void> _pickStartDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startDate ?? now),
    );

    if (pickedTime == null) return;
    if (!mounted) return;

    setState(() {
      _startDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _pickEndDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endDate ?? _startDate ?? now),
    );

    if (pickedTime == null) return;
    if (!mounted) return;

    setState(() {
      _endDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _editExpectedDuration() async {
    final hourController = TextEditingController(
      text: _expectedDurationMinutes == null ? '' : (_expectedDurationMinutes! ~/ 60).toString(),
    );
    final minuteController = TextEditingController(
      text: _expectedDurationMinutes == null ? '' : (_expectedDurationMinutes! % 60).toString(),
    );

    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('持续时长'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hourController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '小时'),
            ),
            TextField(
              controller: minuteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '分钟'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, -1),
            child: const Text('清空'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final hours = int.tryParse(hourController.text.trim()) ?? 0;
              final minutes = int.tryParse(minuteController.text.trim()) ?? 0;
              if (hours < 0 || minutes < 0) {
                Navigator.pop(context);
                return;
              }
              Navigator.pop(context, hours * 60 + minutes);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() {
      _expectedDurationMinutes = result == -1 ? null : result;
    });
  }

  Future<void> _editRepeatRule() async {
    final result = await Navigator.push<RepeatRule>(
      context,
      MaterialPageRoute(
        builder: (_) => RepeatRuleEditorPage(rule: _repeatRule),
      ),
    );

    if (result == null) return;

    setState(() {
      _repeatRule = result;
    });
  }

  Future<void> _saveTask() async {
    if (_title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务名称不能为空')),
      );
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    int? nextRepeatRuleId = _repeatRuleId;

    if (_repeatRule != null) {
      if (nextRepeatRuleId == null) {
        nextRepeatRuleId = await _repeatRuleDao.insert(_repeatRule!);
      } else {
        _repeatRule!.id = nextRepeatRuleId;
        await _repeatRuleDao.update(_repeatRule!);
      }
    } else {
      nextRepeatRuleId = null;
    }

    final task = Task(
      id: _taskId,
      title: _title,
      description: _description.isEmpty ? null : _description,
      taskBookId: _taskBookId,
      color: _color,
      startDate: _startDate?.millisecondsSinceEpoch,
      endDate: _endDate?.millisecondsSinceEpoch,
      expectedDuration: _expectedDurationMinutes,
      repeatRuleId: nextRepeatRuleId,
      timelineDisplayMask: _timelineDisplayMask,
      timelineGranularity: _timelineGranularity.join(','),
      notifyAtStart: _notifyAtStart ? 1 : 0,
      notifyBeforeStartMinutes: _notifyBeforeStartMinutes,
      notifyAtEnd: _notifyAtEnd ? 1 : 0,
      notifyBeforeEndMinutes: _notifyBeforeEndMinutes,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    if (_isCreate) {
      final id = await _taskDao.insert(task);
      task.id = id;
    } else {
      await _taskDao.update(task);
    }

    await NotificationService.syncTaskNotifications(task);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _deleteTask() async {
    if (_taskId == null) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: const Text('确认删除该任务吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    await _taskDao.delete(_taskId!);
    await NotificationService.cancelTaskNotifications(_taskId!);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _editReminder() async {
    final (startDays, startHours, startMinutes) = _splitMinutes(_notifyBeforeStartMinutes);
    final (endDays, endHours, endMinutes) = _splitMinutes(_notifyBeforeEndMinutes);
    final startDayController = TextEditingController(text: startDays == 0 ? '' : '$startDays');
    final startHourController = TextEditingController(text: startHours == 0 ? '' : '$startHours');
    final startMinuteController = TextEditingController(text: startMinutes == 0 ? '' : '$startMinutes');
    final endDayController = TextEditingController(text: endDays == 0 ? '' : '$endDays');
    final endHourController = TextEditingController(text: endHours == 0 ? '' : '$endHours');
    final endMinuteController = TextEditingController(text: endMinutes == 0 ? '' : '$endMinutes');
    bool notifyAtStart = _notifyAtStart;
    bool notifyAtEnd = _notifyAtEnd;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('系统提醒'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: notifyAtStart,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('开始时提醒'),
                  onChanged: (value) {
                    setDialogState(() {
                      notifyAtStart = value ?? false;
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '开始前天'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: startHourController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '开始前小时'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: startMinuteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '开始前分钟'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: notifyAtEnd,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('结束时提醒'),
                  onChanged: (value) {
                    setDialogState(() {
                      notifyAtEnd = value ?? false;
                    });
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: endDayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '结束前天'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endHourController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '结束前小时'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: endMinuteController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '结束前分钟'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    setState(() {
      _notifyAtStart = notifyAtStart;
      _notifyAtEnd = notifyAtEnd;
      _notifyBeforeStartMinutes = _toMinutes(
        days: int.tryParse(startDayController.text.trim()) ?? 0,
        hours: int.tryParse(startHourController.text.trim()) ?? 0,
        minutes: int.tryParse(startMinuteController.text.trim()) ?? 0,
      );
      _notifyBeforeEndMinutes = _toMinutes(
        days: int.tryParse(endDayController.text.trim()) ?? 0,
        hours: int.tryParse(endHourController.text.trim()) ?? 0,
        minutes: int.tryParse(endMinuteController.text.trim()) ?? 0,
      );
    });
  }

  bool _hasDisplayFlag(int flag) {
    return (_timelineDisplayMask & flag) != 0;
  }

  void _setDisplayFlag(int flag, bool enabled) {
    setState(() {
      if (enabled) {
        _timelineDisplayMask |= flag;
      } else {
        _timelineDisplayMask &= ~flag;
      }
    });
  }

  void _toggleGranularity(String part, bool selected) {
    setState(() {
      if (selected) {
        if (!_timelineGranularity.contains(part)) {
          _timelineGranularity.add(part);
        }
      } else {
        _timelineGranularity.remove(part);
        if (_timelineGranularity.isEmpty) {
          _timelineGranularity.add('day');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String? taskBookName;
    for (final book in _books) {
      if (book.id == _taskBookId) {
        taskBookName = book.name;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? '创建任务' : '任务详情'),
        actions: [
          if (!_isCreate)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteTask,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTask,
          ),
        ],
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('任务名称'),
            subtitle: Text(_title.isEmpty ? '未设置' : _title),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editTitle,
          ),
          ListTile(
            title: const Text('任务描述'),
            subtitle: Text(_description.isEmpty ? '未设置' : _description),
            trailing: const Icon(Icons.edit_outlined),
            onTap: _editDescription,
          ),
          ListTile(
            title: const Text('任务本'),
            subtitle: Text(taskBookName ?? '未归类'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickTaskBook,
          ),
          ListTile(
            title: const Text('开始日期'),
            subtitle: Text(_startDate == null ? '未设置' : _formatDateTime(_startDate!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickStartDateTime,
            onLongPress: () {
              setState(() {
                _startDate = null;
              });
            },
          ),
          ListTile(
            title: const Text('结束日期'),
            subtitle: Text(_endDate == null ? '未设置' : _formatDateTime(_endDate!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickEndDateTime,
            onLongPress: () {
              setState(() {
                _endDate = null;
              });
            },
          ),
          ListTile(
            title: const Text('持续时长'),
            subtitle: Text(_expectedDurationMinutes == null ? '未设置' : _formatHoursMinutes(_expectedDurationMinutes!)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editExpectedDuration,
          ),
          ListTile(
            title: const Text('任务颜色'),
            subtitle: Text(_color == null ? '不显示颜色' : '点击修改颜色'),
            trailing: _color == null
                ? const Icon(Icons.visibility_off_outlined)
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(_color!),
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: _pickColor,
          ),
          ListTile(
            title: const Text('系统提醒'),
            subtitle: Text(_reminderSummary()),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editReminder,
          ),
          ListTile(
            title: const Text('重复规则'),
            subtitle: Text(_repeatRuleLabel(_repeatRule)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _editRepeatRule,
            onLongPress: () {
              setState(() {
                _repeatRule = null;
                _repeatRuleId = null;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '时间信息显示项（多选）',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          CheckboxListTile(
            value: _hasDisplayFlag(_displayElapsed),
            title: const Text('显示已开始时间'),
            onChanged: (value) => _setDisplayFlag(_displayElapsed, value ?? false),
          ),
          CheckboxListTile(
            value: _hasDisplayFlag(_displayRemaining),
            title: const Text('显示剩余时间'),
            onChanged: (value) => _setDisplayFlag(_displayRemaining, value ?? false),
          ),
          CheckboxListTile(
            value: _hasDisplayFlag(_displayDuration),
            title: const Text('显示持续时长'),
            onChanged: (value) => _setDisplayFlag(_displayDuration, value ?? false),
          ),
          CheckboxListTile(
            value: _hasDisplayFlag(_displaySinceLast),
            title: const Text('显示距上次'),
            onChanged: (value) => _setDisplayFlag(_displaySinceLast, value ?? false),
          ),
          CheckboxListTile(
            value: _hasDisplayFlag(_displayUntilNext),
            title: const Text('显示距下次'),
            onChanged: (value) => _setDisplayFlag(_displayUntilNext, value ?? false),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              '时间颗粒度（多选）',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: _allGranularity.map((part) {
                final selected = _timelineGranularity.contains(part);
                return FilterChip(
                  selected: selected,
                  label: Text(_granularityLabel(part)),
                  onSelected: (value) => _toggleGranularity(part, value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(
              '提示：长按“开始日期/结束日期/重复规则”可清空。',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  String _granularityLabel(String part) {
    switch (part) {
      case 'year':
        return '年';
      case 'month':
        return '月';
      case 'day':
        return '日';
      case 'hour':
        return '小时';
      case 'minute':
        return '分钟';
      default:
        return part;
    }
  }

  String _formatDateTime(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatHoursMinutes(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '$h小时 $m分钟';
  }

  String _formatReminderOffset(int minutes) {
    final days = minutes ~/ (24 * 60);
    final hours = (minutes % (24 * 60)) ~/ 60;
    final mins = minutes % 60;
    final parts = <String>[];
    if (days > 0) parts.add('$days天');
    if (hours > 0) parts.add('$hours小时');
    if (mins > 0 || parts.isEmpty) parts.add('$mins分钟');
    return parts.join('');
  }

  (int, int, int) _splitMinutes(int? totalMinutes) {
    if (totalMinutes == null || totalMinutes <= 0) {
      return (0, 0, 0);
    }
    final days = totalMinutes ~/ (24 * 60);
    final hours = (totalMinutes % (24 * 60)) ~/ 60;
    final mins = totalMinutes % 60;
    return (days, hours, mins);
  }

  int? _toMinutes({
    required int days,
    required int hours,
    required int minutes,
  }) {
    final total = days * 24 * 60 + hours * 60 + minutes;
    return total <= 0 ? null : total;
  }

  String _reminderSummary() {
    final parts = <String>[];
    if (_notifyAtStart) {
      parts.add('开始时');
    }
    if (_notifyBeforeStartMinutes != null && _notifyBeforeStartMinutes! > 0) {
      parts.add('开始前${_formatReminderOffset(_notifyBeforeStartMinutes!)}');
    }
    if (_notifyAtEnd) {
      parts.add('结束时');
    }
    if (_notifyBeforeEndMinutes != null && _notifyBeforeEndMinutes! > 0) {
      parts.add('结束前${_formatReminderOffset(_notifyBeforeEndMinutes!)}');
    }
    if (parts.isEmpty) {
      return '未设置';
    }
    return parts.join('、');
  }

  String _repeatRuleLabel(RepeatRule? rule) {
    if (rule == null || rule.repeatType == null) {
      return '不重复';
    }

    switch (rule.repeatType) {
      case 'daily':
        return '每天';
      case 'weekly':
        return '每周';
      case 'monthly_day':
        return '每月几号';
      case 'monthly_week':
        return '每月第几周';
      case 'yearly':
        return '每年';
      case 'workday':
        return '工作日';
      default:
        return rule.repeatType!;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../database/dao/taskBookDao.dart';
import '../../database/dao/taskDao.dart';
import '../../models/task.dart';
import '../../models/taskBook.dart';
import '../../services/dataTransferService.dart';
import '../../services/widgetServices.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _busy = false;

  String _configuredWidgetMode = 'today';
  int? _configuredWidgetTaskBookId;
  List<int> _configuredWidgetTaskIds = [];
  int? _bookWidgetTaskBookId;
  List<int> _selectedWidgetTaskIds = [];

  List<TaskBook> _books = [];
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadWidgetConfigData();
  }

  Future<void> _loadWidgetConfigData() async {
    final books = await TaskBookDao().getAll();
    final tasks = await TaskDao().getAll();
    final configured = await WidgetService.loadWidgetConfig(scope: WidgetService.scopeConfigured);
    final book = await WidgetService.loadWidgetConfig(scope: WidgetService.scopeBook);
    final selected = await WidgetService.loadWidgetConfig(scope: WidgetService.scopeSelected);

    if (!mounted) return;

    setState(() {
      _books = books;
      _tasks = tasks;
      _configuredWidgetMode = configured['mode'] as String? ?? 'today';
      _configuredWidgetTaskBookId = configured['task_book_id'] as int?;
      _configuredWidgetTaskIds = (configured['task_ids'] as List? ?? []).whereType<int>().toList();
      _bookWidgetTaskBookId = book['task_book_id'] as int?;
      _selectedWidgetTaskIds = (selected['task_ids'] as List? ?? []).whereType<int>().toList();
    });
  }

  Future<void> _saveConfiguredWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeConfigured,
      mode: _configuredWidgetMode,
      taskBookId: _configuredWidgetTaskBookId,
      taskIds: _configuredWidgetTaskIds,
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('按设置小组件配置已更新')),
    );
  }

  Future<void> _saveBookWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeBook,
      mode: 'book',
      taskBookId: _bookWidgetTaskBookId,
      taskIds: const [],
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('任务本小组件配置已更新')),
    );
  }

  Future<void> _saveSelectedWidgetConfig() async {
    await WidgetService.saveWidgetConfig(
      scope: WidgetService.scopeSelected,
      mode: 'selected',
      taskBookId: null,
      taskIds: _selectedWidgetTaskIds,
    );
    await WidgetService.syncWidgetData();
    await WidgetService.refreshWidget();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('选定日程小组件配置已更新')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ExpansionTile(
            initiallyExpanded: true,
            title: const Text('按设置小组件配置'),
            subtitle: const Text('对应“日程（按设置）”小组件'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _configuredWidgetMode,
                decoration: const InputDecoration(
                  labelText: '显示模式',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'today', child: Text('今日日程')),
                  DropdownMenuItem(value: 'book', child: Text('指定任务本')),
                  DropdownMenuItem(value: 'selected', child: Text('指定一个或多个任务')),
                ],
                onChanged: (value) {
                  setState(() {
                    _configuredWidgetMode = value ?? 'today';
                  });
                },
              ),
              const SizedBox(height: 12),
              if (_configuredWidgetMode == 'book')
                DropdownButtonFormField<int?>(
                  initialValue: _configuredWidgetTaskBookId,
                  decoration: const InputDecoration(
                    labelText: '任务本',
                    border: OutlineInputBorder(),
                  ),
                  items: _books
                      .map(
                        (book) => DropdownMenuItem<int?>(
                          value: book.id,
                          child: Text(book.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _configuredWidgetTaskBookId = value;
                    });
                  },
                ),
              if (_configuredWidgetMode == 'selected')
                OutlinedButton.icon(
                  onPressed: () => _pickWidgetTasks(configured: true),
                  icon: const Icon(Icons.checklist),
                  label: Text('已选择 ${_configuredWidgetTaskIds.length} 个任务，点击修改'),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saveConfiguredWidgetConfig,
                icon: const Icon(Icons.save),
                label: const Text('保存小组件配置'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('任务本小组件配置'),
            subtitle: const Text('对应“任务本日程”小组件'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              DropdownButtonFormField<int?>(
                initialValue: _bookWidgetTaskBookId,
                decoration: const InputDecoration(
                  labelText: '任务本',
                  border: OutlineInputBorder(),
                ),
                items: _books
                    .map(
                      (book) => DropdownMenuItem<int?>(
                        value: book.id,
                        child: Text(book.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _bookWidgetTaskBookId = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saveBookWidgetConfig,
                icon: const Icon(Icons.save),
                label: const Text('保存任务本小组件配置'),
              ),
            ],
          ),
          ExpansionTile(
            title: const Text('选定日程小组件配置'),
            subtitle: const Text('对应“选定日程”小组件'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickWidgetTasks(configured: false),
                icon: const Icon(Icons.checklist),
                label: Text('已选择 ${_selectedWidgetTaskIds.length} 个任务，点击修改'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saveSelectedWidgetConfig,
                icon: const Icon(Icons.save),
                label: const Text('保存选定日程小组件配置'),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('导出全部数据 (JSON)'),
            subtitle: const Text('导出 task_books/tasks/repeat_rules/task_records'),
            onTap: _busy ? null : _exportJson,
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('导入全部数据 (JSON)'),
            subtitle: const Text('导入会覆盖当前所有数据'),
            onTap: _busy ? null : _importJson,
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Future<void> _pickWidgetTasks({required bool configured}) async {
    final selected = configured ? {..._configuredWidgetTaskIds} : {..._selectedWidgetTaskIds};

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('选择任务'),
          content: SizedBox(
            width: 520,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final task in _tasks)
                  CheckboxListTile(
                    value: selected.contains(task.id),
                    title: Text(task.title),
                    onChanged: (value) {
                      if (task.id == null) return;
                      setDialogState(() {
                        if (value == true) {
                          selected.add(task.id!);
                        } else {
                          selected.remove(task.id!);
                        }
                      });
                    },
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
      if (configured) {
        _configuredWidgetTaskIds = selected.toList();
      } else {
        _selectedWidgetTaskIds = selected.toList();
      }
    });
  }

  Future<void> _exportJson() async {
    setState(() {
      _busy = true;
    });

    try {
      final jsonText = await DataTransferService.exportAllAsJson();

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('导出 JSON'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: SelectableText(jsonText),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: jsonText));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制到剪贴板')),
                  );
                },
                child: const Text('复制'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('关闭'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _importJson() async {
    final controller = TextEditingController();

    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入 JSON'),
          content: SizedBox(
            width: 560,
            child: TextField(
              controller: controller,
              minLines: 12,
              maxLines: 20,
              decoration: const InputDecoration(
                hintText: '请粘贴导出的 JSON 文本',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('开始导入'),
            ),
          ],
        );
      },
    );

    if (shouldImport != true) {
      return;
    }

    final jsonText = controller.text.trim();

    if (jsonText.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入 JSON 内容')),
      );
      return;
    }

    setState(() {
      _busy = true;
    });

    try {
      await DataTransferService.importAllFromJson(jsonText);
      await _loadWidgetConfigData();
      await WidgetService.syncWidgetData();
      await WidgetService.refreshWidget();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('导入成功，返回主页后可下拉刷新任务本和任务列表')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }
}

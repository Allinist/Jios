import 'package:flutter/material.dart';

import '../../database/dao/taskBookDao.dart';
import '../../database/dao/taskDao.dart';
import '../../models/taskBook.dart';

class TaskBookEditPage extends StatefulWidget {
  final TaskBook? book;

  const TaskBookEditPage({super.key, this.book});

  @override
  State<TaskBookEditPage> createState() => _TaskBookEditPageState();
}

class _TaskBookEditPageState extends State<TaskBookEditPage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _dao = TaskBookDao();
  final _taskDao = TaskDao();

  String? _color;

  bool get _isCreate => widget.book == null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.book?.name ?? '';
    _descController.text = widget.book?.description ?? '';
    _color = widget.book?.color;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('任务本名称不能为空')),
      );
      return;
    }

    if (_isCreate) {
      await _dao.insert(
        TaskBook(
          name: name,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          color: _color,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } else {
      final updated = TaskBook(
        id: widget.book!.id,
        name: name,
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        color: _color,
        createdAt: widget.book!.createdAt,
      );
      await _dao.update(updated);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务本'),
        content: const Text('删除任务本不会删除任务，原任务会变成未归类。是否继续？'),
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

    if (confirmed != true || widget.book?.id == null) {
      return;
    }

    await _taskDao.clearTaskBookId(widget.book!.id!);
    await _dao.delete(widget.book!.id!);

    if (!mounted) return;
    Navigator.pop(context, true);
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

    final picked = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('任务本颜色'),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colors
              .map(
                (color) => GestureDetector(
                  onTap: () => Navigator.pop(context, color.toARGB32().toString()),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: _color == color.toARGB32().toString() ? 3 : 1,
                        color: _color == color.toARGB32().toString() ? Colors.black : Colors.black26,
                      ),
                    ),
                  ),
                ),
              )
              .toList()
            ..insert(
              0,
              GestureDetector(
                onTap: () => Navigator.pop(context, "__none__"),
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
      _color = picked == '__none__' ? null : picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreate ? '新增任务本' : '编辑任务本'),
        actions: [
          if (!_isCreate)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '名称',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '描述',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('任务本颜色'),
            subtitle: Text(_color == null ? '无颜色（默认）' : '已选择颜色'),
            trailing: _color == null
                ? const Icon(Icons.visibility_off_outlined)
                : Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Color(int.parse(_color!)),
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: _pickColor,
          ),
        ],
      ),
    );
  }
}

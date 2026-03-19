import 'package:flutter/material.dart';

import '../../../database/dao/taskBookDao.dart';
import '../../../models/taskBook.dart';
import '../../taskBook/taskBookEditPage.dart';

class TaskBookFilter extends StatefulWidget {
  final int? selectedTaskBookId;
  final ValueChanged<int?> onChanged;

  const TaskBookFilter({
    super.key,
    required this.selectedTaskBookId,
    required this.onChanged,
  });

  @override
  State<TaskBookFilter> createState() => _TaskBookFilterState();
}

class _TaskBookFilterState extends State<TaskBookFilter> {
  final _dao = TaskBookDao();
  List<TaskBook> _books = [];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    await _dao.ensureDefaultBooks();
    final books = await _dao.getAll();

    if (!mounted) return;

    setState(() {
      _books = books;
    });
  }

  Future<void> _editBook(TaskBook book) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskBookEditPage(book: book)),
    );

    if (changed == true) {
      await _loadBooks();

      final stillExists = _books.any((b) => b.id == widget.selectedTaskBookId);
      if (!stillExists && widget.selectedTaskBookId != null) {
        widget.onChanged(null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          _buildChip(
            label: '全部',
            selected: widget.selectedTaskBookId == null,
            onTap: () => widget.onChanged(null),
          ),
          const SizedBox(width: 8),
          for (final book in _books) ...[
            _buildChip(
              label: book.name,
              selected: widget.selectedTaskBookId == book.id,
              onTap: () => widget.onChanged(book.id),
              onLongPress: () => _editBook(book),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

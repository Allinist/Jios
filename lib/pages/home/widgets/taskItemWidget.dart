import 'package:flutter/material.dart';

import '../../../models/task.dart';

class TaskItemWidget extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onCompletedChanged;
  final List<String> rightAlignedLines;

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onCompletedChanged,
    this.rightAlignedLines = const [],
  });

  @override
  Widget build(BuildContext context) {
    final color = task.color == null ? null : Color(task.color!);
    final completed = task.status == 'completed';

    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: completed,
        onChanged: (value) {
          if (value == null) return;
          onCompletedChanged?.call(value);
        },
      ),
      title: Row(
        children: [
          if (color != null)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          Expanded(
            child: Text(
              task.title,
              style: TextStyle(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.black54 : null,
              ),
            ),
          ),
        ],
      ),
      subtitle: task.description == null || task.description!.isEmpty
          ? null
          : Text(
              task.description!,
              style: TextStyle(
                decoration: completed ? TextDecoration.lineThrough : null,
                color: completed ? Colors.black45 : null,
              ),
            ),
      trailing: rightAlignedLines.isEmpty
          ? const Icon(Icons.chevron_right)
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 160),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: rightAlignedLines
                    .map(
                      (text) => Text(
                        text,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: completed ? Colors.black38 : Colors.black54,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../models/repeatRule.dart';
import '../../models/rules/timeRange.dart';

class TimeRangeEditor extends StatefulWidget {
  final RepeatRule rule;
  final VoidCallback onChanged;

  const TimeRangeEditor({
    super.key,
    required this.rule,
    required this.onChanged,
  });

  @override
  State<TimeRangeEditor> createState() => _TimeRangeEditorState();
}

class _TimeRangeEditorState extends State<TimeRangeEditor> {
  TimeOfDay? start;
  TimeOfDay? end;

  @override
  Widget build(BuildContext context) {
    widget.rule.timeRanges ??= [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: start ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (picked == null) return;
                  setState(() {
                    start = picked;
                  });
                },
                child: Text(start == null ? '开始时间' : _timeToString(start!)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: end ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if (picked == null) return;
                  setState(() {
                    end = picked;
                  });
                },
                child: Text(end == null ? '结束时间' : _timeToString(end!)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            if (start == null || end == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请先选择开始和结束时间')),
              );
              return;
            }

            final startMinutes = start!.hour * 60 + start!.minute;
            final endMinutes = end!.hour * 60 + end!.minute;

            if (endMinutes <= startMinutes) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('结束时间必须晚于开始时间')),
              );
              return;
            }

            widget.rule.timeRanges!.add(
              TimeRange(
                start: _timeToString(start!),
                end: _timeToString(end!),
              ),
            );

            widget.onChanged();
            setState(() {
              start = null;
              end = null;
            });
          },
          child: const Text('添加时间段'),
        ),
        const SizedBox(height: 10),
        if (widget.rule.timeRanges!.isEmpty)
          const Text(
            '未设置时间段',
            style: TextStyle(color: Colors.black54),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(widget.rule.timeRanges!.length, (index) {
              final item = widget.rule.timeRanges![index];
              return InputChip(
                label: Text('${item.start} - ${item.end}'),
                onDeleted: () {
                  setState(() {
                    widget.rule.timeRanges!.removeAt(index);
                  });
                  widget.onChanged();
                },
              );
            }),
          ),
      ],
    );
  }

  String _timeToString(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

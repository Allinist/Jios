import 'package:flutter/material.dart';

import '../../models/repeatRule.dart';
import 'monthDaySelector.dart';
import 'monthWeekSelector.dart';
import 'timeRangeEditor.dart';
import 'weekDaySelector.dart';

class RepeatRuleEditorPage extends StatefulWidget {
  final RepeatRule? rule;

  const RepeatRuleEditorPage({super.key, this.rule});

  @override
  State<RepeatRuleEditorPage> createState() => _RepeatRuleEditorPageState();
}

class _RepeatRuleEditorPageState extends State<RepeatRuleEditorPage> {
  late RepeatRule rule;

  @override
  void initState() {
    super.initState();
    rule = widget.rule ?? RepeatRule();
    rule.interval ??= 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('周期规则'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                rule = RepeatRule(interval: 1);
              });
            },
            child: const Text('清空'),
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, rule.repeatType == null ? null : rule);
            },
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section(
            title: '重复类型',
            child: DropdownButtonFormField<String>(
              initialValue: rule.repeatType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('选择重复类型'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('每天')),
                DropdownMenuItem(value: 'weekly', child: Text('每周')),
                DropdownMenuItem(value: 'monthly_day', child: Text('每月几号')),
                DropdownMenuItem(value: 'monthly_week', child: Text('每月第几周')),
                DropdownMenuItem(value: 'yearly', child: Text('每年（一天）')),
                DropdownMenuItem(value: 'workday', child: Text('工作日')),
              ],
              onChanged: (value) {
                setState(() {
                  rule.repeatType = value;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          _section(
            title: '重复间隔',
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      final current = rule.interval ?? 1;
                      rule.interval = current > 1 ? current - 1 : 1;
                    });
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      '每 ${rule.interval ?? 1} 个周期',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      rule.interval = (rule.interval ?? 1) + 1;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (rule.repeatType != null)
            _section(
              title: '规则细节',
              child: _buildRuleEditor(),
            ),
          if (rule.repeatType != null) const SizedBox(height: 12),
          _section(
            title: '时间段（可选）',
            child: TimeRangeEditor(
              rule: rule,
              onChanged: () {
                setState(() {});
              },
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '提示：不选择重复类型时表示“不重复”。',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildRuleEditor() {
    switch (rule.repeatType) {
      case 'weekly':
        return WeekDaySelector(
          rule: rule,
          onChanged: () => setState(() {}),
        );
      case 'monthly_day':
        return MonthDaySelector(
          rule: rule,
          onChanged: () => setState(() {}),
        );
      case 'monthly_week':
        return MonthWeekSelector(
          rule: rule,
          onChanged: () => setState(() {}),
        );
      case 'yearly':
        return _buildYearlyPicker(context);
      default:
        return const Text('当前类型无需额外细节设置');
    }
  }

  Widget _buildYearlyPicker(BuildContext context) {
    String label = '未选择';
    if (rule.yearDays != null && rule.yearDays!.isNotEmpty) {
      label = rule.yearDays!.first;
    }

    return Row(
      children: [
        Expanded(
          child: Text('每年的一天：$label'),
        ),
        OutlinedButton(
          onPressed: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: now,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );

            if (picked == null) return;

            setState(() {
              final key = '${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              rule.yearDays = [key];
            });
          },
          child: const Text('选择日期'),
        ),
      ],
    );
  }
}

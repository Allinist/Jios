import 'package:flutter/material.dart';
import '../../models/repeatRule.dart';
import '../../models/rules/monthWeekRule.dart';

class MonthWeekSelector extends StatefulWidget {

  final RepeatRule rule;

  final VoidCallback onChanged;

  const MonthWeekSelector({
    super.key,
    required this.rule,
    required this.onChanged,
  });

  @override
  State<MonthWeekSelector> createState() => _MonthWeekSelectorState();

}

class _MonthWeekSelectorState extends State<MonthWeekSelector> {

  int week = 1;

  int weekday = 1;

  @override
  Widget build(BuildContext context) {

    widget.rule.monthWeeks ??= [];

    return Column(

      children: [

        DropdownButton<int>(

          value: week,

          items: List.generate(5, (index) {

            int value = index + 1;

            return DropdownMenuItem(
              value: value,
              child: Text("第$value周"),
            );

          }),

          onChanged: (value) {

            setState(() {
              week = value!;
            });

          },

        ),

        DropdownButton<int>(

          value: weekday,

          items: List.generate(7, (index) {

            int value = index + 1;

            return DropdownMenuItem(
              value: value,
              child: Text("周$value"),
            );

          }),

          onChanged: (value) {

            setState(() {
              weekday = value!;
            });

          },

        ),

        ElevatedButton(

          onPressed: () {

            widget.rule.monthWeeks!.add(
              MonthWeekRule(
                week: week,
                weekday: weekday,
              ),
            );

            widget.onChanged();

          },

          child: const Text("添加规则"),

        )

      ],

    );

  }

}

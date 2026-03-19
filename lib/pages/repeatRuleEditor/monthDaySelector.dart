import 'package:flutter/material.dart';
import '../../models/repeatRule.dart';

class MonthDaySelector extends StatefulWidget {

  final RepeatRule rule;

  final VoidCallback onChanged;

  const MonthDaySelector({
    super.key,
    required this.rule,
    required this.onChanged,
  });

  @override
  State<MonthDaySelector> createState() => _MonthDaySelectorState();

}

class _MonthDaySelectorState extends State<MonthDaySelector> {

  @override
  Widget build(BuildContext context) {

    widget.rule.monthDays ??= [];

    return Wrap(

      spacing: 6,
      runSpacing: 6,

      children: List.generate(31, (index) {

        int day = index + 1;

        bool selected =
            widget.rule.monthDays!.contains(day);

        return ChoiceChip(

          label: Text("$day"),

          selected: selected,

          onSelected: (value) {

            setState(() {

              if (selected) {

                widget.rule.monthDays!.remove(day);

              } else {

                widget.rule.monthDays!.add(day);

              }

            });

            widget.onChanged();

          },

        );

      }),

    );

  }

}
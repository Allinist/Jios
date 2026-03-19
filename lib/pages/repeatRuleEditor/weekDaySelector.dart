import 'package:flutter/material.dart';
import '../../models/repeatRule.dart';

class WeekDaySelector extends StatefulWidget {

  final RepeatRule rule;

  final VoidCallback onChanged;

  const WeekDaySelector({
    super.key,
    required this.rule,
    required this.onChanged,
  });

  @override
  State<WeekDaySelector> createState() => _WeekDaySelectorState();

}

class _WeekDaySelectorState extends State<WeekDaySelector> {

  final List<String> weekLabels = [
    "一","二","三","四","五","六","日"
  ];

  @override
  Widget build(BuildContext context) {

    widget.rule.weekDays ??= [];

    return Wrap(

      spacing: 8,

      children: List.generate(7, (index) {

        int weekday = index + 1;

        bool selected =
            widget.rule.weekDays!.contains(weekday);

        return ChoiceChip(

          label: Text(weekLabels[index]),

          selected: selected,

          onSelected: (value) {

            setState(() {

              if (selected) {

                widget.rule.weekDays!.remove(weekday);

              } else {

                widget.rule.weekDays!.add(weekday);

              }

            });

            widget.onChanged();

          },

        );

      }),

    );

  }

}
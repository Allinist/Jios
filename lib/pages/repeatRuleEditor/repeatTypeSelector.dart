import 'package:flutter/material.dart';
import '../../models/repeatRule.dart';

class RepeatTypeSelector extends StatelessWidget {

  final RepeatRule rule;

  final VoidCallback onChanged;

  const RepeatTypeSelector({
    super.key,
    required this.rule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        const Text(
          "重复类型",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        DropdownButton<String>(

          value: rule.repeatType,

          hint: const Text("选择类型"),

          items: const [

            DropdownMenuItem(
              value: "daily",
              child: Text("每天"),
            ),

            DropdownMenuItem(
              value: "weekly",
              child: Text("每周"),
            ),

            DropdownMenuItem(
              value: "monthly_day",
              child: Text("每月几号"),
            ),

            DropdownMenuItem(
              value: "monthly_week",
              child: Text("每月第几个周几"),
            ),

            DropdownMenuItem(
              value: "yearly",
              child: Text("每年"),
            ),

            DropdownMenuItem(
              value: "workday",
              child: Text("工作日"),
            ),

          ],

          onChanged: (value) {

            rule.repeatType = value;

            onChanged();

          },

        )

      ],

    );

  }

}
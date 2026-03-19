import 'package:flutter/material.dart';

class AddTaskButton extends StatelessWidget {
  const AddTaskButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'schedule_add_task_fab',
      child: const Icon(Icons.add),
      onPressed: () {
        Navigator.pushNamed(context, '/createTask');
      },
    );
  }
}

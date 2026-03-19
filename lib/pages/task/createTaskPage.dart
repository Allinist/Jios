import 'package:flutter/material.dart';

import 'taskDetailPage.dart';

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskDetailPage.create();
  }
}

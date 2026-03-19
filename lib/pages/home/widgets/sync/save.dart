import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../models/task.dart';

Future<void> saveWidgetData(List<Task> tasks) async {

  final prefs = await SharedPreferences.getInstance();

  List<Map<String, dynamic>> data = tasks.map((e) {

    return {
      "title": e.title,
    };

  }).toList();

  await prefs.setString(
    "widget_tasks",
    jsonEncode(data),
  );

}
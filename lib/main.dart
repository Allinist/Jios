import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/main/mainNavigationPage.dart';
import 'pages/task/createTaskPage.dart';

const MethodChannel _widgetClickChannel = MethodChannel('widget_click');

Future<void> _initWidgetClickChannel() async {
  _widgetClickChannel.setMethodCallHandler((call) async {
    if (call.method == 'open') {
      // 跳到首页或某个页面
    }
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _initWidgetClickChannel();
  runApp(const DayMasterApp());
}

class DayMasterApp extends StatelessWidget {
  const DayMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jios',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigationPage(),
      routes: {
        '/createTask': (_) => const CreateTaskPage(),
      },
    );
  }
}

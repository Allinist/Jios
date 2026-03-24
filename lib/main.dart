import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pages/main/mainNavigationPage.dart';
import 'pages/task/createTaskPage.dart';
import 'services/appThemeService.dart';
import 'services/notificationService.dart';
import 'services/widgetServices.dart';

const MethodChannel _widgetClickChannel = MethodChannel('widget_click');

Future<void> _initWidgetClickChannel() async {
  _widgetClickChannel.setMethodCallHandler((call) async {
    if (call.method == 'open') {
      // 跳到首页或某个页面
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initWidgetClickChannel();
  NotificationService.requestPermission();
  await AppThemeService.init();
  await WidgetService.syncWidgetData();
  await WidgetService.refreshWidget();
  runApp(const DayMasterApp());
}

class DayMasterApp extends StatelessWidget {
  const DayMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppThemeService.notifier,
      builder: (context, theme, _) {
        return MaterialApp(
          title: 'Jios',
          theme: AppThemeService.buildTheme(theme),
          home: const MainNavigationPage(),
          routes: {
            '/createTask': (_) => const CreateTaskPage(),
          },
        );
      },
    );
  }
}

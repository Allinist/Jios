import 'package:flutter/services.dart';

const platform =
    MethodChannel('widget_refresh');

Future<void> refreshWidget() async {

  try {
    await platform.invokeMethod('reload');
  } catch (e) {}
}
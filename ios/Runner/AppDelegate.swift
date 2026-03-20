/*
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
*/

/*
 import UIKit
 import Flutter
 
 @UIApplicationMain
 @objc class AppDelegate: FlutterAppDelegate {
 
 override func application(
 _ application: UIApplication,
 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
 ) -> Bool {
 
 UserDefaults.standard = UserDefaults(suiteName: "com.example.jios.jiosWidget")!
 
 return super.application(application, didFinishLaunchingWithOptions: launchOptions)
 }
 
 }
 
 import WidgetKit
 
 let controller = FlutterMethodChannel(
 name: "widget_refresh",
 binaryMessenger: window.rootViewController!.binaryMessenger
 )
 
 controller.setMethodCallHandler { call, result in
 
 if call.method == "reload" {
 
 WidgetCenter.shared.reloadAllTimelines()
 
 result(nil)
 }
 
 }
 */
import UIKit
import Flutter
import WidgetKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)
    guard let registrar = self.registrar(forPlugin: "AppDelegateChannels") else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    let messenger = registrar.messenger()

    let channel = FlutterMethodChannel(
        name: "widget_refresh",
        binaryMessenger: messenger
    )
    let notificationChannel = FlutterMethodChannel(
        name: "task_notification",
        binaryMessenger: messenger
    )

    channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in

      if call.method == "reload" {
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)
      } else if call.method == "save_shared_string" {
        guard let args = call.arguments as? [String: Any],
              let key = args["key"] as? String,
              let value = args["value"] as? String else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Expected key/value string arguments",
              details: nil
            )
          )
          return
        }

        let suite = (args["suite"] as? String) ?? "group.com.example.jios"
        if let sharedDefaults = UserDefaults(suiteName: suite) {
          sharedDefaults.set(value, forKey: key)
          sharedDefaults.synchronize()
        } else {
          UserDefaults.standard.set(value, forKey: key)
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }

    }

    notificationChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "request_permission":
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
          result(nil)
        }
      case "cancel_task_notifications":
        guard let args = call.arguments as? [String: Any],
              let taskId = args["task_id"] as? Int else {
          result(nil)
          return
        }
        self?.cancelTaskNotifications(taskId: taskId)
        result(nil)
      case "sync_task_notifications":
        guard let args = call.arguments as? [String: Any],
              let taskId = args["task_id"] as? Int else {
          result(nil)
          return
        }
        self?.syncTaskNotifications(taskId: taskId, args: args)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func cancelTaskNotifications(taskId: Int) {
    let center = UNUserNotificationCenter.current()
    let ids = [
      "task_\(taskId)_start_at",
      "task_\(taskId)_start_before",
      "task_\(taskId)_end_at",
      "task_\(taskId)_end_before",
    ]
    center.removePendingNotificationRequests(withIdentifiers: ids)
    center.removeDeliveredNotifications(withIdentifiers: ids)
  }

  private func syncTaskNotifications(taskId: Int, args: [String: Any]) {
    cancelTaskNotifications(taskId: taskId)

    let status = (args["status"] as? String) ?? "active"
    if status == "completed" {
      return
    }

    let title = (args["title"] as? String) ?? "任务提醒"
    let startMillis = args["start_date"] as? Int
    let endMillis = args["end_date"] as? Int
    let notifyAtStart = (args["notify_at_start"] as? Bool) ?? false
    let notifyAtEnd = (args["notify_at_end"] as? Bool) ?? false
    let notifyBeforeStartMinutes = args["notify_before_start_minutes"] as? Int
    let notifyBeforeEndMinutes = args["notify_before_end_minutes"] as? Int

    if notifyAtStart, let startMillis {
      scheduleNotification(
        id: "task_\(taskId)_start_at",
        title: "任务开始提醒",
        body: title,
        date: Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000.0)
      )
    }

    if let startMillis, let offset = notifyBeforeStartMinutes, offset > 0 {
      let base = Date(timeIntervalSince1970: TimeInterval(startMillis) / 1000.0)
      scheduleNotification(
        id: "task_\(taskId)_start_before",
        title: "任务即将开始",
        body: "\(title)（\(offset)分钟前）",
        date: base.addingTimeInterval(TimeInterval(-offset * 60))
      )
    }

    if notifyAtEnd, let endMillis {
      scheduleNotification(
        id: "task_\(taskId)_end_at",
        title: "任务结束提醒",
        body: title,
        date: Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000.0)
      )
    }

    if let endMillis, let offset = notifyBeforeEndMinutes, offset > 0 {
      let base = Date(timeIntervalSince1970: TimeInterval(endMillis) / 1000.0)
      scheduleNotification(
        id: "task_\(taskId)_end_before",
        title: "任务即将结束",
        body: "\(title)（\(offset)分钟前）",
        date: base.addingTimeInterval(TimeInterval(-offset * 60))
      )
    }
  }

  private func scheduleNotification(id: String, title: String, body: String, date: Date) {
    if date <= Date() {
      return
    }

    let center = UNUserNotificationCenter.current()
    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default

    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

    center.add(request) { _ in }
  }

}

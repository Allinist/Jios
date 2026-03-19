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

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    GeneratedPluginRegistrant.register(with: self)

    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let channel = FlutterMethodChannel(
        name: "widget_refresh",
        binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { call, result in

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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

}

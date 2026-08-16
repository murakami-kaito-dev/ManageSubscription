import Flutter
import UIKit
#if canImport(WidgetKit)
import WidgetKit
#endif

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Home-screen widget bridge: the Dart side (WidgetBridge) hands us a JSON
    // payload; we store it in the shared App Group defaults and ask WidgetKit
    // to reload. Kept as a tiny hand-rolled channel — no plugin dependency.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "submana/widget", binaryMessenger: controller.binaryMessenger)
      channel.setMethodCallHandler { call, result in
        guard call.method == "update",
              let args = call.arguments as? [String: Any],
              let group = args["group"] as? String,
              let kind = args["kind"] as? String,
              let payload = args["payload"] as? String
        else {
          result(FlutterMethodNotImplemented)
          return
        }
        UserDefaults(suiteName: group)?.set(payload, forKey: "widget_payload")
        #if canImport(WidgetKit)
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadTimelines(ofKind: kind)
        }
        #endif
        result(nil)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

import UIKit
import Flutter
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.thiendevlab.cute_pixel/widget",
                                      binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "updateWidget" {
        if let args = call.arguments as? [String: Any],
           let pixelsJson = args["pixels"] as? String {
          self.updateWidget(pixelsJson: pixelsJson)
          result(true)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func updateWidget(pixelsJson: String) {
    if let sharedDefaults = UserDefaults(suiteName: "group.com.thiendevlab.cute-pixel") {
      sharedDefaults.set(pixelsJson.data(using: .utf8), forKey: "pixelData")
      sharedDefaults.synchronize()
      if #available(iOS 14.0, *) {
        WidgetCenter.shared.reloadAllTimelines()
      }
    }
  }
}

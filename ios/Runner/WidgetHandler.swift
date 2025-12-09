import Flutter
import UIKit
import WidgetKit

@objc class WidgetHandler: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.thiendevlab.cute_pixel/widget", binaryMessenger: registrar.messenger())
        let instance = WidgetHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateWidget":
            updateWidget(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func updateWidget(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let pixelsJson = args["pixels"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
            return
        }
        
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.thiendevlab.cute-pixel") else {
            result(FlutterError(code: "SHARED_DEFAULTS_ERROR", message: "Cannot access shared defaults", details: nil))
            return
        }
        
        sharedDefaults.set(pixelsJson.data(using: .utf8), forKey: "pixelData")
        sharedDefaults.synchronize()
        
        if #available(iOS 14.0, *) {
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        result(true)
    }
}
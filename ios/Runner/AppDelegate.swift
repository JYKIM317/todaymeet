import UIKit
import Flutter
import workmanager
import GoogleMaps
import Firebase
import AdSupport
import AppTrackingTransparency

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GMSServices.provideAPIKey("AIzaSyCGoLM2AaiC5sXXLMIA2BTpmL4qgj-80Tw")
    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.registerTask(withIdentifier: "task-identifier")
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    }
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
            // registry in this case is the FlutterEngine that is created in Workmanager's performFetchWithCompletionHandler
            // This will make other plugins available during a background fetch
            GeneratedPluginRegistrant.register(with: registry)
        }
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

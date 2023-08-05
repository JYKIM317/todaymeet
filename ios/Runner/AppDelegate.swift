import UIKit
import Flutter
import workmanager
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBtaFzFYfxQLwAqnf05OaThZ2Ks1ugCYJg")
    GeneratedPluginRegistrant.register(with: self)
    WorkmanagerPlugin.registerTask(withIdentifier: "task-identifier")
    UIApplication.shared.setMinimumBackgroundFetchInterval(TimeInterval(60*15))
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
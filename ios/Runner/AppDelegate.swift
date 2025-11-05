import Flutter
import UIKit
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyDEZD5JDtSClTS3qSrG0OU3dJGo-3OADwY")

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

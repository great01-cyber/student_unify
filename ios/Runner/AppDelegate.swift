import UIKit
import Flutter
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    print("🚀 didFinishLaunching called")

    GMSServices.provideAPIKey("AIzaSyDEZD5JDtSClTS3qSrG0OU3dJGo-3OADwY")
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      print("🔔 Permission granted:", granted, "error:", String(describing: error))
      if granted {
        DispatchQueue.main.async {
          UIApplication.shared.registerForRemoteNotifications()
          print("✅ registerForRemoteNotifications called")
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("✅ didRegisterForRemoteNotificationsWithDeviceToken fired")

    Messaging.messaging().apnsToken = deviceToken

    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    print("📱 APNs Device Token:", token)

    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("❌ Failed to register for remote notifications:", error.localizedDescription)
  }
}

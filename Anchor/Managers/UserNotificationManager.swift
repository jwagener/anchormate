import Foundation
import UserNotifications


class UserNotificationManager {
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { (authorized, error) in
            NSLog("Notifcation Authorized")
        }
    }
}

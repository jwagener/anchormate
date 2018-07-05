import Foundation
import UserNotifications

class UserNotificationManager: NSObject {
    enum NotificationType: String { case AnchorAlarm, BatteryAlarm, Fallback }

    private var notifcationCenter: UNUserNotificationCenter {
        return UNUserNotificationCenter.current()
    }

    override init() {
        super.init()
        notifcationCenter.delegate = self
    }

    func requestPermission() {
        notifcationCenter.requestAuthorization(options: [.alert, .sound, .badge, .criticalAlert]) { (authorized, error) in
            NSLog("Notifcation Authorized")
        }
    }

    func resetFallbackNotification() {
        cancelFallbackNotification()
        scheduleFallbackNotification()
    }

    func cancelFallbackNotification() {
        cancelNotifications(ofType: .Fallback)
    }

    func scheduleFallbackNotification() {
        let content = UNMutableNotificationContent()
        content.body = "WARNING - Anchor Watch could not determine location in the last 5 minutes"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5000, repeats: false)
        let request = UNNotificationRequest(identifier: NotificationType.Fallback.rawValue, content: content, trigger: trigger)

        notifcationCenter.add(request) {(error) in
            if let error = error {
                NSLog("Schedule Notification Error: \(error)")
            }
        }
    }

    func sendAnchorAlarmNotification() {
        let content = UNMutableNotificationContent()
        content.body = "ANCHOR ALARM - You've left the safe anchor zone."
        let request = UNNotificationRequest(identifier: NotificationType.AnchorAlarm.rawValue, content: content, trigger: nil)

        notifcationCenter.add(request) {(error) in
            if let error = error {
                NSLog("Schedule Notification Error: \(error)")
            }
        }
    }

    private func cancelNotifications(ofType type: NotificationType) {
        cancelPendingNotifications(ofType: type)
        cancelDeliveredNotifications(ofType: type)
    }

    private func cancelPendingNotifications(ofType type: NotificationType) {
        notifcationCenter.removePendingNotificationRequests(withIdentifiers: [type.rawValue])
    }

    private func cancelDeliveredNotifications(ofType type: NotificationType) {
        notifcationCenter.removeDeliveredNotifications(withIdentifiers: [type.rawValue])
    }

    private func sendNotification(_ text: String) {
//        let content = UNMutableNotificationContent()
//        content.body = text
//        let request = UNNotificationRequest(identifier: NotificationType.Driving.rawValue, content: content, trigger: nil)
//
//        notifcationCenter.add(request) {(error) in
//            if let error = error {
//                NSLog("Schedule Notification Error: \(error)")
//            }
//        }
    }
}

extension UserNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        /* this makes iOS to present notification also when app is in foreground */
        completionHandler(.alert)
    }
}

import Foundation
import UserNotifications
import UIKit

private let fallbackNotificationInterval = 5000.0

class UserNotificationManager: NSObject {
    enum NotificationType: String { case AnchorAlarm, BatteryAlarm, Fallback }

    private var notifcationCenter: UNUserNotificationCenter {
        return UNUserNotificationCenter.current()
    }

    private var alarmSound: UNNotificationSound {
        return UNNotificationSound(named: "Alarm.wav")
    }

    override init() {
        super.init()
        notifcationCenter.delegate = self
    }

    func requestPermission() {
        notifcationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { (authorized, error) in
            NSLog("Notifcation Authorized")
        }
    }

    /// Generic Notificaton Methods

    private func sendNotification(type: NotificationType, content: UNNotificationContent, trigger: UNNotificationTrigger? = nil) {
        let request = UNNotificationRequest(identifier: type.rawValue, content: content, trigger: trigger)
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

    /// Specific Notification Methods

    func sendBatteryAlarmNotification() {
        let content = UNMutableNotificationContent()
        content.title = "BATTERY WARNING"
        content.body = "You're battery level is getting low. Please charge your device to continue anchor watch."
        content.sound = alarmSound
        sendNotification(type: .BatteryAlarm, content: content)
    }

    func sendAnchorAlarmNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ANCHOR ALARM"
        content.body = "You've left the safe anchor zone."
        content.sound = alarmSound
        sendNotification(type: .AnchorAlarm, content: content)
    }

    func scheduleFallbackNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ANCHOR WARNING"
        content.body = "Could not determine your location in the last 5 minutes."
        content.sound = alarmSound
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: fallbackNotificationInterval, repeats: false)

        sendNotification(type: .Fallback, content: content, trigger: trigger)
    }

    func resetFallbackNotification() {
        cancelFallbackNotification()
        scheduleFallbackNotification()
    }

    func cancelFallbackNotification() {
        cancelNotifications(ofType: .Fallback)
    }
}

extension UserNotificationManager: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        /* Present notifications as usual, when app is in foreground */
        completionHandler([.sound, .alert])
    }
}

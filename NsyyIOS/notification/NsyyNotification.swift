//
//  NsyyNotification.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/25.
//

import Foundation
import UserNotifications
import Vapor
import UIKit

class NsyyNotification: NSObject {
    
    static var badge = 0
    
    func requestPermission() {
        let center = UNUserNotificationCenter.current()
        
        center.delegate = self
        
        // ask for permission to push notification
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("\(#function) Error: \(error)")
            }
            
            if granted {
                print("\(#function) 消息通知权限已开启😃")
            } else {
                print("\(#function) 为获取消息通知权限😣")
            }
        }
        
        // set notification actions
        let remindLaterAction = UNNotificationAction(identifier: "REMIND_LATER", title: "Remind Me Later", options: UNNotificationActionOptions(rawValue: 0))
        let cancelAction = UNNotificationAction(identifier: "CANCEL", title: "Cancel", options: UNNotificationActionOptions(rawValue: 0))
        
        // set category to all notifications
        let category = UNNotificationCategory(
            identifier: "MY_CATEGORY",
            actions: [remindLaterAction, cancelAction],
            intentIdentifiers: [],
            options: .customDismissAction)
        center.setNotificationCategories([category])
        
        
    }
    
    func routes_notification(_ app: Application) throws {
        
        // 请求正文不会被收集到缓冲区中。
        app.on(.POST, "notification", body: .stream) { req -> ReturnData in
            let notification = try req.content.decode(Notification.self)
            print("title: \(notification.title) , context: \(notification.context)")
            
            // 消息通知
            self.createNotification(title: notification.title, context: notification.context)
            
            return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "Message notification successful")
        }
    }
    
    func createNotification(title: String, context: String) {
        
        NsyyNotification.badge = NsyyNotification.badge + 1
        
        let content = UNMutableNotificationContent()
        content.title = "南石医院"
        // content.subtitle = "消息通知"
        content.body = "[" + title + "]" + " " + context
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "MY_CATEGORY"
        content.badge = (NsyyNotification.badge) as NSNumber
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("\(#function) 消息通知失败: \(error)")
            } else {
                print("\(#function) 消息通知成功: title： \(title), context: \(context)")
            }
        }
    }
    
    
}


// delegate methods
extension NsyyNotification: UNUserNotificationCenterDelegate {
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.actionIdentifier {
        case "REMIND_LATER":
            let notiContent = response.notification.request.content
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: "FIVE_SECONDS", content: notiContent, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { _ in
                print("Remind later")
            }
        default:
            break
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        NsyyNotification.badge = 0
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // New in iOS 10, we can show notifications when app is in foreground, by calling completion handler with our desired presentation type.
        
        completionHandler([.alert, .badge, .sound])
    }
}

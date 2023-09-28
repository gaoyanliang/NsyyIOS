//
//  NsyyNotification.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/25.
//

import Foundation
import UserNotifications
import Vapor

class NsyyNotification {
    
    // 请求通知权限
    static func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error = error {
                            print("Oops, we've met an error: \(error)")
            }
            
            if granted {
                print("===> Notification authorization granted")
            } else {
                print("===> Notification authorization denied")
            }
        }
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
        let content = UNMutableNotificationContent()
        content.title = "南石医院"
        // content.subtitle = "消息通知"
        content.body = "[" + title + "]" + " " + context
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "MY_CATEGORY"
        
        // show this notification five seconds from now
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)

        // choose a random identifier
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // add our notification request
        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("===> 消息通知失败: \(error)")
            } else {
                print("===> 消息通知成功: title： \(title), context: \(context)")
            }
        }
    }
    
}

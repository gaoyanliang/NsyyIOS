//
//  AppDelegate.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/22.
//

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // set delegate
        UNUserNotificationCenter.current().delegate = self
        
        // ask for permission to push notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error: \(error)")
            }
            
            if granted {
                print("The user grants us the permission to push notifications😃")
                
                // NsyyNotification.createNotification()
                
            } else {
                print("The user denies our permission😣")
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
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let server = NsyyWebServer(port: 8081)
        server.start()
        
        return true
    }


    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}



// delegate methods
extension AppDelegate: UNUserNotificationCenterDelegate {
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
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // New in iOS 10, we can show notifications when app is in foreground, by calling completion handler with our desired presentation type.
        
        completionHandler(.alert)
    }
}

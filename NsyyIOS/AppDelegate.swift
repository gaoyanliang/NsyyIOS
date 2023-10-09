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
    
    var notification: NsyyNotification = NsyyNotification()
    var bluetooth: NsyyBluetooth = NsyyBluetooth()
    

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        notification.requestPermission()
        
        bluetooth.setUpBluetooth()
        
        // Create location manager singleton
        let manager = SignificantLocationManager.sharedManager
        manager.isUnStartBackgoundLocation = true
        
        // 检查是否因位置发生重大变化而启动
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            manager.isRunFromeSystem = true
            // BackgroundLocationManager.sharedManager.sendLocalNoification()
            print("\(#function) 自动启动完成")
            notification.createNotification(title: "南石医院", context: "欢迎使用南石医院 APP，祝您度过愉快的一天 (*￣︶￣)")
        }
        
        manager.startMonitoringSignificantLocationChanges()
        
        let server = NsyyWebServer(port: 8081)
        server.start()
        
        // Reset the app badge to zero
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundLocationManager.sharedManager.startChickBgTime()
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
    
    // Function to reset the badge
    func resetBadge() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            if settings.authorizationStatus == .authorized {
                DispatchQueue.main.async {
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
            }
        }
    }

    // Call this function when you want to reset the badge, for example, in your AppDelegate
    func applicationDidBecomeActive(_ application: UIApplication) {
        resetBadge()
    }
}

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
        
        // Create location manager singleton
        let manager = SignificantLocationManager.sharedManager
        manager.isUnStartBackgoundLocation = true
        
        // 检查是否因位置发生重大变化而启动
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            manager.isRunFromeSystem = true
            print("\(#function) 自动启动完成")
        }
        // 实现自动启动 关键API 在注册此接口后，被用户或系统强行退出后，系统依然可以自动启动应用，进行关键位置定位 
        manager.startMonitoringSignificantLocationChanges()
        
        let server = NsyyWebServer(port: 8081)
        server.start()
        
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
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            NsyyNotification.badge = 0
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // This method is triggered when the app becomes active again after being in the background or minimized.
        // You can perform actions you need when the app is brought back to the foreground here.
        resetBadge()
    }
}

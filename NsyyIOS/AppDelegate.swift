//
//  AppDelegate.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/22.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var isFirstStart = true
    var notification: NsyyNotification = NsyyNotification()
    //var bluetooth: NsyyBluetooth = NsyyBluetooth()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //bluetooth.setUpBluetooth()
        notification.requestPermission()
        
        // Create location manager singleton
        let manager = SignificantLocationManager.sharedManager
        manager.isUnStartBackgoundLocation = true
        
//        // 检查是否因位置发生重大变化而启动
//        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
//            manager.isRunFromeSystem = true
//            print("\(#function) 自动启动完成")
//        }
        
        // 实现自动启动 关键API 在注册此接口后，被用户或系统强行退出后，系统依然可以自动启动应用，进行关键位置定位
        manager.startMonitoringSignificantLocationChanges()
        
//        let server = NsyyWebServer(port: 8081)
//        server.start()
        
        return true
    }

    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        print("\(#function) 被调用")
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        print("\(#function) 被调用")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        BackgroundLocationManager.sharedManager.startChickBgTime()
    }

}

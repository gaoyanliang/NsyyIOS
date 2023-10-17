//
//  SceneDelegate.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/22.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        print("\(#function) 被调用")
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let response = connectionOptions.notificationResponse {
           //get your launch info from here
            if response.notification.request.content.userInfo[UIApplication.LaunchOptionsKey.location] != nil {
                NsyyNotification().createNotification(title: "Test", context: "南石医院 app 自动启动")
            }
        }
        
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        print("\(#function) 被调用")
    }

    // 当场景从非活动状态转为活动状态时调用。
    // 使用此方法重新启动场景处于非活动状态时暂停（或尚未启动）的任何任务。
    func sceneDidBecomeActive(_ scene: UIScene) {
        print("\(#function) 重置角标数量")
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
            NsyyNotification.badge = 0
        }
    }

    // 当场景从活动状态转为非活动状态时调用。
    // 由于临时中断（如来电），可能会出现这种情况。
    func sceneWillResignActive(_ scene: UIScene) {
        print("\(#function) 程序中断")
    }

    // 当场景从后台过渡到前台时调用。
    // 使用此方法可以撤销进入背景时所作的更改。
    func sceneWillEnterForeground(_ scene: UIScene) {
        print("\(#function) 程序进入前台")
        BackgroundLocationManager.sharedManager.applicationWillBeActive()
    }

    // 当场景从前景过渡到背景时调用。
    // 使用此方法保存数据、释放共享资源并存储足够的场景特定状态信息 以将场景恢复到当前状态。
    func sceneDidEnterBackground(_ scene: UIScene) {
        print("\(#function) 程序进入后台")
        BackgroundLocationManager.sharedManager.applicationEnterBackground()
    }


}


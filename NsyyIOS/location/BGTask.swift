//
//  BGTask.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/8.
//

import Foundation
import UIKit

class BGTask {
    static let shared = BGTask()
    
    private var bgTaskIdList = [UIBackgroundTaskIdentifier]()
    private var masterTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    
    private init() {
        bgTaskIdList = [UIBackgroundTaskIdentifier]()
        masterTaskId = UIBackgroundTaskIdentifier.invalid
    }
    
    //开启新的后台任务
    func beginNewBackgroundTask() -> UIBackgroundTaskIdentifier {
        let application = UIApplication.shared
        var bgTaskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
        
        if application.responds(to: #selector(UIApplication.beginBackgroundTask(expirationHandler:))) {
            bgTaskId = application.beginBackgroundTask {
                print("\(#function) 后台任务过期 \(bgTaskId)")
                
                // 过期任务从后台数据中删除
                if let id = self.bgTaskIdList.firstIndex(of: bgTaskId) {
                    self.bgTaskIdList.remove(at: id)
                }
                
                bgTaskId = UIBackgroundTaskIdentifier.invalid
                application.endBackgroundTask(bgTaskId)
            }
        }
        
        // 如果上次记录的后台任务失效了，就记录最新的任务为主任务
        if masterTaskId == UIBackgroundTaskIdentifier.invalid {
            masterTaskId = bgTaskId
            print("\(#function) 开启后台任务 \(bgTaskId)")
        } else {
            // 如果上次开启的后台任务还未结束，就提前关闭了，使用最新的后台任务
            print("\(#function) 保持后台任务 \(bgTaskId)")
            bgTaskIdList.append(bgTaskId)
            endBackGroundTask(all: false) // 留下最新创建的后台任务
        }
        
        return bgTaskId
    }
    

     //  yes 关闭所有 ,no 只留下主后台任务
     // yes 为了去处多余残留的后台任务，只保留最新的创建的
    func endBackGroundTask(all: Bool) {
        let application = UIApplication.shared
        
        //如果为all 清空后台任务数组
        //不为all 留下数组最后一个后台任务,也就是最新开启的任务
        if application.responds(to: #selector(UIApplication.endBackgroundTask(_:))) {
            let endIndex = all ? bgTaskIdList.count : bgTaskIdList.count - 1
            for i in 0..<endIndex {
                let bgTaskId = bgTaskIdList[i]
                print("\(#function) 关闭后台任务 \(bgTaskId)")
                application.endBackgroundTask(bgTaskId)
                bgTaskIdList.remove(at: 0)
            }
        }
        
        if bgTaskIdList.count > 0 {
            print("\(#function) 后台任务 \(bgTaskIdList[0]) 正在保持运行, 当前主任务为 \(masterTaskId)")
        }
        
        if all {
            application.endBackgroundTask(masterTaskId)
            masterTaskId = UIBackgroundTaskIdentifier.invalid
        }
    }
}

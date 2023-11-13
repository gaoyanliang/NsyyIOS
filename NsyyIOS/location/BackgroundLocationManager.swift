//
//  BackgroundLocationManager.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/8.
//

import Foundation
import CoreLocation
import UIKit

class BackgroundLocationManager: CLLocationManager, CLLocationManagerDelegate {
    
    static let sharedManager: BackgroundLocationManager = {
        let manager = BackgroundLocationManager()
        // 定位精度
        manager.distanceFilter = kCLLocationAccuracyBest
        if #available(iOS 8.0, *) {
            manager.requestAlwaysAuthorization()
        }
        if #available(iOS 9.0, *) {
            // 允许后台定位
            manager.allowsBackgroundLocationUpdates = true
        }
        manager.num = 0
        manager.delegate = manager
        manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        return manager
    }()
    
    private var num: Int = 0 //定位计数，用以判断每次程序启动定位了几次
    private var bgTaskTimer: Timer?
    private var isStartUpdatingLocation: Bool = false
    private var timeInterval: Int = 0
    
    private override init() {
        super.init()
        
//        NotificationCenter.default.addObserver(BackgroundLocationManager.self, selector: #selector(applicationEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
//        NotificationCenter.default.addObserver(BackgroundLocationManager.self, selector: #selector(applicationWillBeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        
        self.locationConvented(location: loc)
        
        if UIApplication.shared.applicationState == .background {
            print("\(#function) 程序手动启动，-后台-第\(num)次定位")
        } else {
            print("\(#function) 程序手动启动，-前台-第\(num)次定位")
        }
        

        num += 1
        _ = BGTask.shared.beginNewBackgroundTask()
        print("\(#function) 程序手动启动，-前台-第\(num)次定位")
        stopUpdatingLocation()
        isStartUpdatingLocation = false
    }
    
    func startChickBgTime() {
        bgTaskTimer?.invalidate()
        bgTaskTimer = nil
        bgTaskTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(bgTaskTimerAction), userInfo: nil, repeats: true)
        _ = BGTask.shared.beginNewBackgroundTask()
    }
    
    @objc private func bgTaskTimerAction() {
        let backgroundTimeRemaining = UIApplication.shared.backgroundTimeRemaining
        if backgroundTimeRemaining == .greatestFiniteMagnitude {
            print("后台任务剩余运行时间 = Undetermined")
        } else {
            print("\(#function) 后台任务剩余运行时间 = \(backgroundTimeRemaining)")
            if backgroundTimeRemaining < 30 && !isStartUpdatingLocation {
                print("\(#function) 开始定位")
                isStartUpdatingLocation = true
                startUpdatingLocation()
            }
        }
    }
    
    func applicationWillBeActive() {
        print("\(#function) 结束后台检测")
        bgTaskTimer?.invalidate()
        bgTaskTimer = nil
        
        BGTask.shared.endBackGroundTask(all: true)
    }
    
    func applicationEnterBackground() {
        print("\(#function) 进入后台 开始后台时间检测")
        self.startChickBgTime()
    }
    


    
    // 将 CLLocation 转换为具体的地址
    private func locationConvented(location: CLLocation) {
        var interval = Int(Date().timeIntervalSince1970)
        if interval - self.timeInterval < 30 {
            return
        }
        self.timeInterval = interval
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("\(#function) Reverse geocoding failed with error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            SignificantLocationManager.cur_location = ""
            
            if let country = placemark.country {
                SignificantLocationManager.cur_location.append(country)
            }
            
            if let country_code = placemark.isoCountryCode {
                SignificantLocationManager.cur_location.append("(" + country_code + ")")
            }
            
            // 省
            if let administrative_area = placemark.administrativeArea {
                SignificantLocationManager.cur_location.append(administrative_area)
            }
            
            if let locality = placemark.locality {
                SignificantLocationManager.cur_location.append(locality)
            }
            
            if let sub_locality = placemark.subLocality {
                SignificantLocationManager.cur_location.append(sub_locality)
            }

            if let stree_name = placemark.thoroughfare {
                SignificantLocationManager.cur_location.append(stree_name)
            }
            
            print("\(#function) BackgroundLocationManager 更新地址: \(SignificantLocationManager.cur_location)")
            
        }
    }
    

    
}

//
//  SignificantLocationManager.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/8.
//

import Foundation
import CoreLocation
import UIKit
import Vapor

/**
 * 1.重大位置定位，该定位开启后，无论应用是否启动，是否被用户手动退出，当位置发生重大变化时，系统都会后台唤醒程序
 * 2.重大位置变化定位是基于基站（即：移动、联通、电信等基站）进行定位的，如果手机没有SIM卡，那该功能不能使用
 */
class SignificantLocationManager: CLLocationManager, CLLocationManagerDelegate {
    
    static var cur_location: String = ""
    
    var isRunFromeSystem: Bool = false //是否是系统因为位置发生重大变化，自动启动了程序
    var isUnStartBackgoundLocation: Bool = false
    
    private var num: Int = 0 //定位计数，用以判断每次程序启动定位了几次
    
    // MARK: - 初始化
    /**
     * 1.单例，重大位置改变定位需要使用单例而且必须在 didFinishLaunchingWithOptions 进行初始化
     * 2.因为假如应用被系统或者用户强制退出，当有重大位置改变时候，系统会重新启动程序，从而调用 didFinishLaunchingWithOptions 方法，但是这时候系统后台启动程序，所以只有将SignificantLocationManager的初始化放在didFinishLaunchingWithOptions才能保证每次系统自动启动程序可以进行初始化
     * 3.单例的目的是保证对象不被销毁，也可以保证不会重复创建
     */
    static let sharedManager: SignificantLocationManager = {
        let manager = SignificantLocationManager()
        if #available(iOS 8.0, *) {
            manager.requestAlwaysAuthorization()
        }
        manager.num = 0
        manager.delegate = manager
        return manager
    }()
    
    private override init() {
        super.init()
    }
    
    
    
    // MARK: - 位置更新
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.first else { return }
        
        print("\(#function) 重大位置变更定位 \(loc)")
        self.locationConvented(location: loc)
        
        
        if UIApplication.shared.applicationState == .background {
            print("\(#function) 程序启动 第 \(num) 次定位")
        }
        
        
        num += 1
        
        if UIApplication.shared.applicationState == .background{
            BackgroundLocationManager.sharedManager.startChickBgTime()
        }
        
//        if self.isUnStartBackgoundLocation {
//            if UIApplication.shared.applicationState == .background && !isFirstRun{
//                self.isUnStartBackgoundLocation = true
//                BackgroundLocationManager.sharedManager.startChickBgTime()
//            }
//        }
//        
//        self.isFirstRun = false
    }
    
    
    
    // MARK: - 位置转换
    // 将 CLLocation 转换为具体的地址
    private func locationConvented(location: CLLocation) {
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
            
            print("\(#function) SignificantLocationManager 更新地址: \(SignificantLocationManager.cur_location)")
            
        }
    }
    
    
    // 注册获取位置接口
    func routes_location(_ app: Application) throws {
        app.get("location") { req async -> ReturnData in
            if SignificantLocationManager.cur_location != "" {
                return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: SignificantLocationManager.cur_location)
            } else {
                return ReturnData(isSuccess: false, code: 5001, errorMsg: "Failed to get location: Please check if location services are enabled", data: "")
            }
        }
    }
    
}

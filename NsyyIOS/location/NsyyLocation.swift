//
//  NsyyLocation.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/28.
//

import Foundation
import CoreLocation
import Vapor

class NsyyLocation: NSObject {
    
    // MARK: -
    var mLocationManager: CLLocationManager?
    var mCurrentLocation: CLLocation?
    static var cur_location: String = ""
    var location_update_time = Date()
    
    
    // 申请位置权限 & 获取位置
    func setUpLocation() {
        mLocationManager = CLLocationManager()
        mLocationManager?.delegate = self
        
        // Configure the CLLocationManager to provide the desired accuracy and update frequency for location updates.
        mLocationManager?.desiredAccuracy = kCLLocationAccuracyBest
        mLocationManager?.distanceFilter = 10  // Update if the device has moved by 10 meters // default kCLDistanceFilterNone
        mLocationManager?.allowsBackgroundLocationUpdates = true
        
        // mLocationManager?.requestWhenInUseAuthorization()
        mLocationManager?.requestAlwaysAuthorization()
        
        mLocationManager?.startUpdatingLocation()
    }
    
    // 将 CLLocation 转换为具体的地址
    private func locationConvented(location: CLLocation) {
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("===> Reverse geocoding failed with error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // 清空之前的地址
            print("===> old location is: \(NsyyLocation.cur_location) update time is: \(self.location_update_time)")
            NsyyLocation.cur_location = ""
            self.location_update_time = Date()
            
            if let country = placemark.country {
                NsyyLocation.cur_location.append(country)
                print("===> Location: country: \(country)")
            }
            
            if let country_code = placemark.isoCountryCode {
                NsyyLocation.cur_location.append("(" + country_code + ")")
                print("===> Location: country_code: \(String(describing: placemark.isoCountryCode))")
            }
            
            // 省
            if let administrative_area = placemark.administrativeArea {
                NsyyLocation.cur_location.append(administrative_area)
                print("===> Location: administrative_area: \(administrative_area)")
            }
            
            if let locality = placemark.locality {
                NsyyLocation.cur_location.append(locality)
                print("===> Location: locality: \(locality)")
            }
            
            if let sub_locality = placemark.subLocality {
                NsyyLocation.cur_location.append(sub_locality)
                print("===> Location: sub_locality: \(sub_locality)")
            }

            
            if let stree_name = placemark.thoroughfare {
                NsyyLocation.cur_location.append(stree_name)
                print("===> Location: street name: \(stree_name)")
            }
            
            print("===> cur location: \(NsyyLocation.cur_location) update time is: \(self.location_update_time)")
            
        }
    }
    
    
    func routes_location(_ app: Application) throws {
        app.get("location") { req async -> ReturnData in
            
            print("===> \(NsyyLocation.cur_location) \(self.location_update_time)")
            
            if NsyyLocation.cur_location != "" {
                return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: NsyyLocation.cur_location)
            } else {
                return ReturnData(isSuccess: false, code: 5001, errorMsg: "Failed to get location: Please check if location services are enabled", data: "")
            }
        }
    }
    
}


// 响应 位置&权限变化
extension NsyyLocation: CLLocationManagerDelegate {
    
    // 当位置发生改变时调用
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else {
            return
        }
        
        mCurrentLocation = currentLocation
        print("=====> update location: \(String(describing: mCurrentLocation))")
        print("=====> lat: \(String(format: "%3.5f", arguments: [currentLocation.coordinate.latitude]))")
        print("=====> lng: \(String(format: "%3.5f", arguments: [currentLocation.coordinate.longitude]))")
        print("=====> alt: \(String(format: "%3.5f", arguments: [currentLocation.altitude]))")
        
//        // 测试地址，南石医院
//        let test_location = CLLocation(latitude: 32.992050949153366, longitude: 112.48888564053263)
        self.locationConvented(location: currentLocation)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    // 当权限状态改变时调用
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus){
        
        // TODO: - 测试不开启服务状态时 app 的反应,再决定是否添加一下代码
//        if (!CLLocationManager.locationServicesEnabled()) {
//            print("位置服务不可用🚫")
//        }
        
        switch status {
        case .authorizedAlways:
            print("=====> Authorized")
        case .authorizedWhenInUse:
            print("=====> AuthorizedWhenInUse")
        case .denied:
            print("=====> Denied")
        case .restricted:
            print("=====> 受限")
        case .notDetermined:
            mLocationManager?.requestAlwaysAuthorization()
            print("=====> 用户未确定")
        @unknown default:
            print("default")
        }
    }
    
}

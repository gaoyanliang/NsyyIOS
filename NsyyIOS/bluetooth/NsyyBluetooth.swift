//
//  NsyyBluetooth.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/7.
//

import Foundation
import CoreBluetooth
import UIKit
import Vapor
import WebKit

class NsyyBluetooth: NSObject {
    
    private let BLE_WRITE_UUID = "ffe2"
    private let BLE_NOTIFY_UUID = "ffe1"
    
    static var centralManager:CBCentralManager?
    
    //当前连接的设备
    static var electronicWeigher: CBPeripheral? = nil
    static var scanGun: CBPeripheral? = nil
    static var writeCh: CBCharacteristic? = nil
    static var notifyCh: CBCharacteristic?
    
    // 蓝牙秤 mac address
    static var BLUETOOTH_SCALE_MAC_ADDRESS: String = ""
    // 扫码枪名称
    static var SCAN_GUN_NAME: String = ""
    
    static var webView: WKWebView!
    
    // 接收到的数据
    static var recvData: [String:Double] = [:]
    
    // 申请蓝牙权限
    func setUpBluetooth() {
        NsyyBluetooth.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // 从配置文件中读取蓝牙秤 mac address 以及 扫码枪名称
        if let mac_address = UserDefaults.standard.value(forKey: NsyyConfig.BLUETOOTH_CONFIG_IDENTIFIER) as? String {
            NsyyBluetooth.BLUETOOTH_SCALE_MAC_ADDRESS = mac_address
        }
        if let scan_gun_name = UserDefaults.standard.value(forKey: NsyyConfig.SCAN_GUN_NAME_CONFIG_IDENTIFIER) as? String {
            NsyyBluetooth.SCAN_GUN_NAME = scan_gun_name
        }
    }
    
    static func setWebView(webView: WKWebView) {
        NsyyBluetooth.webView = webView
    }
    
    
    // 注册对外接口
    func routes_bluetooth(_ app: Application) throws {
        
        // 获取电子秤重量
        // 1. 向电子秤发送 “R”
        // 2. 等待电子秤返回重量
        app.get("get_weight") { req async -> WeightReturn in
            
            let isConnect = self.isConnect()
            
            if !isConnect {
                return WeightReturn(res: "获取重量失败，未成功连接蓝牙设备，请检查配置", code: 20001, bag_weight: 0)
            }
            
            
            if NsyyBluetooth.electronicWeigher?.state != CBPeripheralState.connected {
                return WeightReturn(res: "获取重量失败，未成功连接蓝牙设备，请检查配置", code: 20002, bag_weight: 0)
            }
            
            self.sendPacketWithPieces(data: "R".data(using: .utf8)!, peripheral: NsyyBluetooth.electronicWeigher!, characteristic: NsyyBluetooth.writeCh!)
            
            if let returnData = NsyyBluetooth.recvData[(NsyyBluetooth.electronicWeigher?.identifier.uuidString)!] {
                return WeightReturn(res: "成功获取重量", code: 20000, bag_weight: returnData)
            } else {
                return WeightReturn(res: "获取重量失败，未接受到电子秤返回的重量", code: 20003, bag_weight: 0)
            }
            
        }
        
        
        // 连接扫码枪 Code scanning gun
        app.get("conn_scan_gun") { req async -> ReturnData in
            
            // 如果正在扫描，直接返回
            if NsyyBluetooth.centralManager?.isScanning == true {
                return ReturnData(isSuccess: true, code: 20000, errorMsg: "", data: "")
            }
                
            // 开始扫描蓝牙设备
            self.startScan()
            
            // 十秒后关闭扫描
            let time = DispatchTime.now() + DispatchTimeInterval.seconds(10)
            DispatchQueue.main.asyncAfter(deadline: time){
                self.stopScan()
            }
                
            return ReturnData(isSuccess: true, code: 20000, errorMsg: "", data: "")
        }
        
    }
    
    
    // 通过配置的 mac address 来确定是否连接到指定蓝牙秤， 没有连接
    func isConnect() -> Bool {
        if let mac_address = UserDefaults.standard.value(forKey: NsyyConfig.BLUETOOTH_CONFIG_IDENTIFIER) as? String {
            NsyyBluetooth.BLUETOOTH_SCALE_MAC_ADDRESS = mac_address
        }
        
        // Access a boolean setting
        if NsyyBluetooth.BLUETOOTH_SCALE_MAC_ADDRESS != "" {
            
            if NsyyBluetooth.electronicWeigher != nil {
                if NsyyBluetooth.electronicWeigher?.state == .connected {
                    print("\(#function) 设备已连接. \(String(describing: NsyyBluetooth.electronicWeigher?.name)) ")
                    return true
                }
                
                print("\(#function) 设备未连接，开始连接 \(String(describing: NsyyBluetooth.electronicWeigher?.name)) ")
                doConnect(peripheral: NsyyBluetooth.electronicWeigher!)
                
                // Delay the task by 0.5 second:
                Thread.sleep(forTimeInterval: 0.5)
                
                return true
            } else {
                return false
            }
        } else {
            print("\(#function) 未发现蓝牙秤 MAC 地址相关配置")
            return false
        }
    }
    
    

    
    //MARK: - Private Method
    
    //连接指定的设备
    func doConnect(peripheral: CBPeripheral) {
        NsyyBluetooth.centralManager?.connect(peripheral, options: nil)
        peripheral.delegate = self
    }
    
    ///断开连接
    func disconnect(peripheral: CBPeripheral) {
        NsyyBluetooth.centralManager?.cancelPeripheralConnection(peripheral)
        print("\(#function) 断开连接 \(peripheral)")
    }
    
    ///开始扫描
    func startScan(serviceUUIDS:[CBUUID]? = nil, options:[String: Any]? = nil) {
        // 从配置文件中读取蓝牙秤 mac address 以及 扫码枪名称
        if let mac_address = UserDefaults.standard.value(forKey: NsyyConfig.BLUETOOTH_CONFIG_IDENTIFIER) as? String {
            NsyyBluetooth.BLUETOOTH_SCALE_MAC_ADDRESS = mac_address
        }
        if let scan_gun_name = UserDefaults.standard.value(forKey: NsyyConfig.SCAN_GUN_NAME_CONFIG_IDENTIFIER) as? String {
            NsyyBluetooth.SCAN_GUN_NAME = scan_gun_name
        }
        
        NsyyBluetooth.centralManager?.scanForPeripherals(withServices: serviceUUIDS, options: options)
        print("\(#function) 开始扫描蓝牙设备")
    }
    
    ///停止扫描
    func stopScan() {
        NsyyBluetooth.centralManager?.stopScan()
        print("\(#function) 停止扫描蓝牙设备")
    }
    
    ///发送数据包给设备
    func sendPacketWithPieces(data:Data, peripheral: CBPeripheral, characteristic: CBCharacteristic, type: CBCharacteristicWriteType = CBCharacteristicWriteType.withResponse) {
        
        let step = 20
        for index in stride(from: 0, to: data.count, by: step) {
            var len = data.count - index
            if len > step {
                len = step
            }
            let pData: Data = (data as NSData).subdata(with: NSRange(location: index, length: len))
            peripheral.writeValue(pData, for: characteristic, type: type)
        }
        
        // Delay the task by 0.2 second:
        Thread.sleep(forTimeInterval: 0.2)
    }
    
}




extension Request {
    func jsonResponse<T: Encodable>(_ data: T) throws -> Response {
        let response = Response()
        try response.content.encode(data, as: .json)
        return response
    }
}



//MARK: - Ble Delegate

extension NsyyBluetooth:CBCentralManagerDelegate {
    
    // MARK: 检查运行这个App的设备是不是支持BLE。
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOn {
                print("\(#function) 蓝牙已开启!")
                
                startScan()
                
                // 十秒后关闭扫描
                let time = DispatchTime.now() + DispatchTimeInterval.seconds(10)
                DispatchQueue.main.asyncAfter(deadline: time){
                    self.stopScan()
                }
                
            } else {
                if central.state == CBManagerState.poweredOff {
                    print("\(#function) 请打开系统蓝牙开关")
                } else if central.state == CBManagerState.unauthorized {
                    print("\(#function) 请打开应用的蓝牙权限")
                } else if central.state == CBManagerState.unknown {
                    print("\(#function) BLE unknown")
                } else if central.state == CBManagerState.resetting {
                    print("\(#function) BLE ressetting")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    
    // 开始扫描之后会扫描到蓝牙设备，扫描到之后走到这个代理方法
    // MARK: 中心管理器扫描到了设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name, deviceName.count > 0 else {
            return
        }
        
        print("\(#function) 发现蓝牙设备: \(String(describing: peripheral.name)), \(peripheral.identifier), \(peripheral.state)")
        
        // 获取蓝牙设备的 mac address
        var macAddress: String! = ""
        if let mData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            macAddress = mData.map { String(format: "%02X", $0) }.joined()
        }
        
        print("\(#function) 蓝牙设备 \(String(describing: peripheral.name))：的 mac 地址为 \(String(describing: macAddress))")

        // 连接电子秤
        if macAddress != "" && NsyyBluetooth.BLUETOOTH_SCALE_MAC_ADDRESS != "" {
            if macAddress.contains(NsyyBluetooth.BLUETOOTH_SCALE_MAC_ADDRESS) {
                print("\(#function) 发现蓝牙秤，开始尝试连接")
                NsyyBluetooth.electronicWeigher = peripheral
                
                if NsyyBluetooth.electronicWeigher?.state == .connected || NsyyBluetooth.electronicWeigher?.state == .connecting {
                    print("\(#function) 蓝牙秤已连接. \(String(describing: NsyyBluetooth.electronicWeigher?.name)) ")
                } else {
                    print("\(#function) 蓝牙秤未连接，开始连接 \(String(describing: NsyyBluetooth.electronicWeigher?.name)) ")
                    doConnect(peripheral: NsyyBluetooth.electronicWeigher!)
                }
            }
        }
        
        // 连接扫码枪，通过名称来匹配扫码枪
        if NsyyBluetooth.SCAN_GUN_NAME != "" && peripheral.name?.contains(NsyyBluetooth.SCAN_GUN_NAME) == true {
            print("\(#function) 发现扫码枪，开始尝试连接")
            NsyyBluetooth.scanGun = peripheral
            
            if NsyyBluetooth.scanGun?.state == .connected || NsyyBluetooth.scanGun?.state == .connecting {
                print("\(#function) 扫码枪已连接. \(String(describing: NsyyBluetooth.scanGun?.name)) ")
            } else {
                print("\(#function) 扫码枪未连接. 开始尝试连接 \(String(describing: NsyyBluetooth.scanGun?.name)) ")
                doConnect(peripheral: NsyyBluetooth.scanGun!)
            }
        }

    }
    
    // MARK: 连接外设成功，开始发现服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("\(#function) 蓝牙设备 \(String(describing: peripheral.name)) 连接成功。")
        
        // 设置代理
        peripheral.delegate = self
        // 开始发现服务
        peripheral.discoverServices(nil)
    }
    
    // MARK: 连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(#function) \(String(describing: peripheral.name)) 连接失败：\(String(describing: error))")
    }
    
    // MARK: 连接丢失
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(#function) \(String(describing: peripheral.name)) 连接丢失：\(String(describing: error))")
    }
}




extension NsyyBluetooth: CBPeripheralDelegate {
    //MARK: 匹配对应服务UUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error  {
            print("\(#function) 设备：\(String(describing: peripheral.name)) 搜索服务(Services)失败：\(error) ")
            return
        }
        
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
            print("\(#function) 搜索到服务：\(String(describing: peripheral.name)), \(service.uuid)")
        }
    }
    
    //MARK: 服务下的特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let _ = error {
            print("\(#function) 设备：\(String(describing: peripheral.name)),  服务(service)：\(String(describing: service.uuid)),  扫描特征(Characteristics)失败：\(String(describing: error)) ")
            return
        }
        
        for characteristic in service.characteristics ?? [] {
            print("\(#function) 设备：\(String(describing: peripheral.name)), 服务(service)：\(String(describing: service.uuid)),  服务下的特征：\(characteristic.uuid) ")
            
            // 开启扫码枪的通知服务，获取扫码之后的值
            if peripheral.name?.contains(NsyyBluetooth.SCAN_GUN_NAME) == true && characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
                continue
            }
            
            // 记录电子秤的服务特征
            if peripheral.name == NsyyBluetooth.electronicWeigher?.name {
                if characteristic.uuid.uuidString.lowercased().isEqual(BLE_WRITE_UUID) {
                    NsyyBluetooth.electronicWeigher = peripheral
                    NsyyBluetooth.writeCh = characteristic
                } else if characteristic.uuid.uuidString.lowercased().isEqual(BLE_NOTIFY_UUID) {
                    //该组参数无用
                    NsyyBluetooth.notifyCh = characteristic
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                
                continue
            }
            //此处代表连接成功
        }
    }
    
    // MARK: 获取外设发来的数据
    // 注意，所有的，不管是 read , notify 的特征的值都是在这里读取
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let _ = error {
            return
        }
        
        if peripheral.name?.contains(NsyyBluetooth.SCAN_GUN_NAME) == true {
            var code = String(decoding: characteristic.value!, as: UTF8.self)
            print("\(#function) 接收到扫码枪返回数据 \(code)")
            
            // 扫码枪返回的数据，有可能会带有回车等字符，需要移除，否则有可能导致 js 调用失败
            code = code.replacingOccurrences(of: "\r", with: "")
            code = code.replacingOccurrences(of: "\n", with: "")

            let jsCode = "receiveScanResult2('\(code)');"
            print("\(#function) 调用 js 方法 \(jsCode)")
            NsyyBluetooth.webView.evaluateJavaScript(jsCode, completionHandler: { (result, error) in
                if let error = error {
                    print("Error calling JavaScript function: \(error)")
                } else if let result = result {
                    print("JavaScript result: \(result)")
                }
            })
            
            return
        }
        
        //拿到设备发送过来的值,传出去并进行处理
        if characteristic.value != nil {
            
            // 电子秤返回的数据为： +  0.88 g
            // 电子秤的单位通过电子秤设置为 kg，所以这里在接收到数据之后，移除单位和 + - 符号后，仅返回数值
            var weight = String(decoding: characteristic.value!, as: UTF8.self)
            weight = weight.replacingOccurrences(of: " ", with: "")
            weight = weight.replacingOccurrences(of: "\r", with: "")
            weight = weight.replacingOccurrences(of: "\n", with: "")
            
            weight = weight.replacingOccurrences(of: "+", with: "")
            weight = weight.replacingOccurrences(of: "-", with: "")
            
            weight = weight.replacingOccurrences(of: "g", with: "")
            weight = weight.replacingOccurrences(of: "k", with: "")
            weight = weight.replacingOccurrences(of: "G", with: "")
            weight = weight.replacingOccurrences(of: "K", with: "")

            weight = weight.components(separatedBy: ",")[2]
            
            if let data: Double = Double(weight) {
                NsyyBluetooth.recvData[peripheral.identifier.uuidString] = data.roundTo(places: 3)
                print("\(#function) 接收到蓝牙设备返回数据 \(String(describing: NsyyBluetooth.recvData[peripheral.identifier.uuidString]))")
            }
           
        }
    }
    
    //MARK: 检测中心向外设写数据是否成功
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("\(#function)\n发送数据失败！错误信息：\(error)")
        } else {
            print("\(#function)\n发送数据成功")
        }
    }
    
}

extension Double {
    /// Rounds the float to decimal places value
    func roundTo(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

}


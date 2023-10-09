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

class NsyyBluetooth: NSObject {
    
    private let BLE_WRITE_UUID = "ffe2"
    private let BLE_NOTIFY_UUID = "ffe1"
    
    static var centralManager:CBCentralManager?
    
    //扫描到的所有设备
    static var bluetoothDeviceArray: [String:CBPeripheral] = [:]
    static var bluetoothDeviceList: [BluetoothDevice] = []
    
    //当前连接的设备
    static var electronicWeigher: CBPeripheral? = nil
    static var writeCh: CBCharacteristic? = nil
    static var notifyCh: CBCharacteristic?
    
    // 接收到的数据
    static var recvData: [String:String] = [:]
    
    // 申请位置权限 & 获取位置
    func setUpBluetooth() {
        NsyyBluetooth.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    
    func routes_bluetooth(_ app: Application) throws {
        
        // 扫描蓝牙设备, 并返回蓝牙设备列表
        app.get("scanning") {req async -> BluetoothReturnData in
            self.startScan()
            return BluetoothReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: NsyyBluetooth.bluetoothDeviceList)
        }
        
        // 连接蓝牙设备
        app.on(.POST, "connect", body: .stream) { req -> ReturnData in
            self.stopScan()
            
            let bluetoothDevice = try req.content.decode(BluetoothDevice.self)
            print("准备连接蓝牙设备： \(bluetoothDevice)")
            
            if let devicePeripheral = NsyyBluetooth.bluetoothDeviceArray[bluetoothDevice.id] {
                // 不管之前是否连接过，先断开连接
                self.disconnect(peripheral: devicePeripheral)
                
                // 重新连接
                self.doConnect(peripheral: devicePeripheral)
                
                return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "Bluetooth device connect successful")
            } else {
                return ReturnData(isSuccess: false, code: 200, errorMsg: "nil", data: "Bluetooth device connect failed, not found cur bluetooth device.")
            }
        }
        
        // 获取电子秤重量
        // 1. 向电子秤发送 “R”
        // 2. 等待电子秤返回重量
        app.get("weight") { req async -> ReturnData in
            if NsyyBluetooth.electronicWeigher?.state != CBPeripheralState.connected {
                return ReturnData(isSuccess: false, code: 200, errorMsg: "获取重量失败，未成功连接当前蓝牙设备", data: "")
            }
            
            self.sendPacketWithPieces(data: "R".data(using: .utf8)!, peripheral: NsyyBluetooth.electronicWeigher!, characteristic: NsyyBluetooth.writeCh!)
            
            if let returnData = NsyyBluetooth.recvData[(NsyyBluetooth.electronicWeigher?.identifier.uuidString)!] {
                return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: returnData)
            } else {
                return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "")
            }
           
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
    }
    
    ///开始扫描
    func startScan(serviceUUIDS:[CBUUID]? = nil, options:[String: Any]? = nil) {
        NsyyBluetooth.centralManager?.scanForPeripherals(withServices: serviceUUIDS, options: options)
        
        // Delay the task by 0.1 second:
        Thread.sleep(forTimeInterval: 0.1)
    }
    
    ///停止扫描
    func stopScan() {
        NsyyBluetooth.centralManager?.stopScan()
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



//MARK: - Ble Delegate

extension NsyyBluetooth:CBCentralManagerDelegate {
    
    // MARK: 检查运行这个App的设备是不是支持BLE。
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        if #available(iOS 10.0, *) {
            if central.state == CBManagerState.poweredOn {
                print("\(#function) 蓝牙已开启！开始扫描蓝牙设备")
                startScan()
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
        
        if NsyyBluetooth.bluetoothDeviceArray.contains(where: { $0.key == peripheral.identifier.uuidString }) {
            return
        }
        
        guard let deviceName = peripheral.name, deviceName.count > 0 else {
            return
        }
        
        print("\(#function) 发现蓝牙设备 peripheral:\(peripheral) \n")
        var macAddress: String! = ""
        if let mData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            let macAddressData: Data = mData.subdata(in: 2..<8)
            macAddress = macAddressData.map { String(format: "%02X", $0) }.joined(separator: ":")
        }
        
        NsyyBluetooth.bluetoothDeviceArray[peripheral.identifier.uuidString] = peripheral
        NsyyBluetooth.bluetoothDeviceList.append(BluetoothDevice(id: peripheral.identifier.uuidString, name: peripheral.name!, macAddress: macAddress))
    }
    
    // MARK: 连接外设成功，开始发现服务
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //连接成功后停止扫描，节省内存
        self.stopScan()
        print("\(#function) 蓝牙设备连接成功。peripheral:\(peripheral)\n")
        
        // 设置代理
        peripheral.delegate = self
        // 开始发现服务
        peripheral.discoverServices(nil)
    }
    
    // MARK: 连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("\(#function)连接外设失败\n\(String(describing: peripheral.name))连接失败：\(String(describing: error))\n")
    }
    
    // MARK: 连接丢失
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("\(#function)连接丢失\n外设：\(String(describing: peripheral.name))\n错误：\(String(describing: error))\n")
    }
}




extension NsyyBluetooth: CBPeripheralDelegate {
    //MARK: 匹配对应服务UUID
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error  {
            print("\(#function)搜索到服务-出错\n设备(peripheral)：\(String(describing: peripheral.name)) 搜索服务(Services)失败：\(error)\n")
            return
        } else {
            print("\(#function)搜索到服务\n设备(peripheral)：\(String(describing: peripheral.name))\n")
        }
        for service in peripheral.services ?? [] {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    //MARK: 服务下的特征
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let _ = error {
            print("\(#function) 发现特征\n设备(peripheral)：\(String(describing: peripheral.name))\n 服务(service)：\(String(describing: service))\n 扫描特征(Characteristics)失败：\(String(describing: error))\n")
            return
        } else {
            print("\(#function)发现特征\n设备(peripheral)：\(String(describing: peripheral.name))\n服务(service)：\(String(describing: service))\n服务下的特征：\(service.characteristics ?? [])\n")
        }
        
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid.uuidString.lowercased().isEqual(BLE_WRITE_UUID) {
                NsyyBluetooth.electronicWeigher = peripheral
                NsyyBluetooth.writeCh = characteristic
            } else if characteristic.uuid.uuidString.lowercased().isEqual(BLE_NOTIFY_UUID) {
                //该组参数无用
                NsyyBluetooth.notifyCh = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
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
        //拿到设备发送过来的值,传出去并进行处理
        // TODO 确定下是否是本次请求
        if characteristic.value != nil {
            
            var weight = String(decoding: characteristic.value!, as: UTF8.self)
            weight = weight.replacingOccurrences(of: " ", with: "")
            weight = weight.replacingOccurrences(of: "\r", with: "")
            weight = weight.replacingOccurrences(of: "\n", with: "")
            weight = weight.components(separatedBy: ",")[2]
            
            NsyyBluetooth.recvData[peripheral.identifier.uuidString] = weight
            print("\(#function) 接收到蓝牙设备返回数据 " + weight)
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


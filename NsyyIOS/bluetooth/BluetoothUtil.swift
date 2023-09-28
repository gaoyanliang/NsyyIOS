//
//  BluetoothUtil.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/27.
//

import CoreBluetooth
import UIKit

class BluetoothUtil {
    
    // MARK: - 变量
    var deviceListData: [DeviceInfo] = []
    var revData: String = ""
    
    // 打开蓝牙
    func openBluetoothAdapter(controller: UIViewController){
        bluetoothManager.onBluetoothAdapterStateChange { ok, errCode, errMsg in
            if ok {
                self.startScan()
            } else {
                if errMsg == "poweredOff" {
                    self.showAlert(controller: controller, title: "提示", content: "请打开系统蓝牙开关") {}
                }else if errMsg == "unauthorized" {
                    self.showAlert(controller: controller, title: "提示", content: "请打开应用的蓝牙权限") {
                        self.gotoSetting()
                    }
                }else{
                    self.showAlert(controller: controller, title: "提示", content: "蓝牙适配器错误，errMsg=" + errMsg) {}
                }
            }
        }
        
        bluetoothManager.onBLEConnectionStateChange { _,_,_ in
            self.showAlert(controller: controller, title: "提示", content: "设备断开链接") {}
        }
        
        bluetoothManager.onBLECharacteristicValueChange {
            str, hexStr in
            self.revData(str: str, hexStr: hexStr)
        }
        
        bluetoothManager.openBluetoothAdapter()
    }
    
    // 扫描蓝牙
    func startScan() {
        bluetoothManager.onBluetoothDeviceFound { id, name, rssi in
            for item in self.deviceListData {
                if item.id == id {
                    item.rssi = rssi
                    item.name = name
                    return
                }
            }
            self.deviceListData.append(DeviceInfo(id: id, name: name, rssi: rssi))
        }
        bluetoothManager.startBluetoothDevicesDiscovery()
    }
    
    
    func closeConnection() {
        bluetoothManager.onBLEConnectionStateChange { _,_,_ in }
        bluetoothManager.closeBLEConnection()
    }
    
    func send() {
        // 发送数据之前先清理上次的数据
        self.clearData()
        
        bluetoothManager.writeBLECharacteristicValue(data: "R", isHex: false)
    }
    
    private func revData(str: String, hexStr: String) {
        let data = self.getTimeString() + hexStr + "\r"
        revData.append(data)
        
        print(data)
    }
    
    private func clearData() {
        revData = ""
    }
    
    
    // MARK: - private tool
    
    // 弹框提示
    private func showAlert(controller: UIViewController, title: String, content: String, cb: @escaping () -> Void) {
        let alertController = UIAlertController(title: title, message: content, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "确定", style: .default, handler: {
            _ in
            cb()
        })
        alertController.addAction(okAction)
        controller.present(alertController, animated: true, completion: nil)
    }
    
    // 进入蓝牙设置页面
    private func gotoSetting(){
        guard let url = URL(string: UIApplication.openSettingsURLString)  else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    func isHexString(data: String) -> Bool {
        let regular = "^[0-9a-fA-F]*$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regular)
        return predicate.evaluate(with: data)
    }

    func getTimeString() -> String {
        let dateformatter = DateFormatter()
        dateformatter.dateFormat = "[HH:mm:ss.SSS]: " // 自定义时间格式
        return dateformatter.string(from: Date())
    }
}

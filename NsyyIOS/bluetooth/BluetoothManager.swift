//
//  BluetoothManager.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/27.
//

import CoreBluetooth

var bluetoothManager = BluetoothManager()

class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // MARK: - 变量
    
    private var ecCBCentralManager: CBCentralManager!
    private var ecBluetoothAdapterStateChangeCallback: (Bool,Int,String) -> Void = { _,_,_ in }
    private var ecPeripheralList: [CBPeripheral] = []
    private var ecBluetoothDeviceFoundCallback: (String, String, Int) -> Void = { _,_,_ in }
    private var ecBLEConnectionStateChangeCallback: (Bool,Int,String) -> Void = { _,_,_ in }
    private var ecPeripheral: CBPeripheral!
    private var discoverServicesCallback: ([CBService]) -> Void = { _ in }
    private var discoverCharacteristicsCallback: ([CBCharacteristic]) -> Void = { _ in }
    private var ecPeripheralCharacteristicWriteUUID: String = "FFF2"
    private var ecPeripheralCharacteristicWrite: CBCharacteristic!
    private var ecBLECharacteristicValueChangeCallback: (String, String) -> Void = { _, _ in }
    
    
    // MARK: - 闭包定义
    func onBluetoothAdapterStateChange(cb: @escaping (Bool,Int,String) -> Void){
        ecBluetoothAdapterStateChangeCallback = cb
    }
    
    func onBluetoothDeviceFound(cb: @escaping (String, String, Int) -> Void){
        ecBluetoothDeviceFoundCallback = cb
    }
    
    func onBLEConnectionStateChange(cb: @escaping (Bool,Int,String) -> Void){
        ecBLEConnectionStateChangeCallback = cb
    }
    
    func onBLECharacteristicValueChange(cb: @escaping (String, String) -> Void) {
        ecBLECharacteristicValueChangeCallback = cb
    }
    
    
    // MARK: - 蓝牙适配器
    func openBluetoothAdapter() {
        ecCBCentralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            ecBluetoothAdapterStateChangeCallback(true,0,"")
        case .unknown:
            ecBluetoothAdapterStateChangeCallback(false,10000,"unknown")
        case .resetting:
            ecBluetoothAdapterStateChangeCallback(false,10001,"resetting")
        case .unsupported:
            ecBluetoothAdapterStateChangeCallback(false,10002,"unsupported")
        case .unauthorized:
            ecBluetoothAdapterStateChangeCallback(false,10003,"unauthorized")
        case .poweredOff:
            ecBluetoothAdapterStateChangeCallback(false,10004,"poweredOff")
        @unknown default:
            ecBluetoothAdapterStateChangeCallback(false,10005,"unknown default")
        }
    }


    // MARK: - 蓝牙扫描
    func startBluetoothDevicesDiscovery() {
        ecPeripheralList.removeAll()
        ecCBCentralManager.scanForPeripherals(withServices: nil, options: nil)
    }
    
    func stopBluetoothDevicesDiscovery() {
        ecCBCentralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == nil { return }
        
//        NSLog(peripheral.name ?? "")
        //NSLog(peripheral.identifier.uuidString)
        //NSLog(ecPeripheralList.description)
        //NSLog(ecPeripheralList.count.description)
        
        var isExist = false
        for item in ecPeripheralList {
            if item.identifier.uuidString == peripheral.identifier.uuidString {
                isExist = true
                break;
            }
        }
        if !isExist {
            ecPeripheralList.append(peripheral)
        }

        ecBluetoothDeviceFoundCallback(peripheral.identifier.uuidString,peripheral.name ?? "", RSSI.intValue)
    }
    

    // MARK: - 蓝牙连接
    func createBLEConnection(id: String) {
        for item in ecPeripheralList {
            if item.identifier.uuidString == id {
                ecCBCentralManager.connect(item, options: nil)
                return
            }
        }
        ecBLEConnectionStateChangeCallback(false,10000,"This device does not exist")
    }
    
    func closeBLEConnection() {
        if(ecPeripheral != nil){
            ecCBCentralManager.cancelPeripheralConnection(ecPeripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        ecPeripheral = peripheral
        ecPeripheral.delegate = self
        self.getBLEDeviceServices {
            services in
            for service in services {
                self.getBLEDeviceCharacteristics(service: service){
                    characteristics in
                    NSLog(service.uuid.uuidString)
                    for characteristic in characteristics{
                        NSLog(characteristic.uuid.uuidString)
                        //NSLog(String(characteristic.properties.rawValue))
                        if (characteristic.properties.rawValue & CBCharacteristicProperties.notify.rawValue)>0{
                            self.notifyBLECharacteristicValueChange(characteristic: characteristic)
                        }
                        if characteristic.uuid.uuidString == self.ecPeripheralCharacteristicWriteUUID {
                            self.ecPeripheralCharacteristicWrite = characteristic
                        }
                    }
                }
            }
            self.ecBLEConnectionStateChangeCallback(true,0,"")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        ecBLEConnectionStateChangeCallback(false,10001,error.debugDescription)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        ecBLEConnectionStateChangeCallback(false,0,"")
    }
    
    func getBLEDeviceServices(cb: @escaping ([CBService]) -> Void) {
        discoverServicesCallback = cb
        ecPeripheral.discoverServices(nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        discoverServicesCallback(peripheral.services ?? [])
    }
    
    func getBLEDeviceCharacteristics(service: CBService, cb: @escaping ([CBCharacteristic]) -> Void) {
        discoverCharacteristicsCallback = cb
        ecPeripheral.discoverCharacteristics(nil, for: service)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        discoverCharacteristicsCallback(service.characteristics ?? [])
    }
    func notifyBLECharacteristicValueChange(characteristic: CBCharacteristic) {
        ecPeripheral.setNotifyValue(true, for: characteristic)
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.value == nil { return }
        let str = String(data: characteristic.value!, encoding: String.Encoding.utf8) ?? ""
        let hexStr = dataToHexString(data: characteristic.value!)
        ecBLECharacteristicValueChangeCallback(str, hexStr)
    }

    func _writeBLECharacteristicValue(data: Data) {
        if ecPeripheralCharacteristicWrite == nil {
            return
        }
        ecPeripheral.writeValue(data, for: ecPeripheralCharacteristicWrite!, type: CBCharacteristicWriteType.withoutResponse)
    }
    
    func writeBLECharacteristicValue(data: String, isHex: Bool) {
        var tempData: Data?
        if isHex {
            tempData = hexStrToData(hexStr: data)
        } else {
            tempData = data.data(using: .utf8)
        }
        if tempData == nil { return }
        _writeBLECharacteristicValue(data: tempData!)
    }

    private func dataToHexString(data: Data) -> String {
        var hexStr = ""
        for byte in [UInt8](data) {
            hexStr += String(format: "%02X ", byte)
        }
        return hexStr
    }
    
    private func hexStrToBytes(hexStr: String) -> [UInt8] {
        var bytes = [UInt8]()
        var sum = 0
        // 整形的 utf8 编码范围
        let intRange = 48...57
        // 小写 a~f 的 utf8 的编码范围
        let lowercaseRange = 97...102
        // 大写 A~F 的 utf8 的编码范围
        let uppercasedRange = 65...70
        for (index, c) in hexStr.utf8CString.enumerated() {
            var intC = Int(c.byteSwapped)
            if intC == 0 {
                break
            } else if intRange.contains(intC) {
                intC -= 48
            } else if lowercaseRange.contains(intC) {
                intC -= 87
            } else if uppercasedRange.contains(intC) {
                intC -= 55
            }
            sum = sum * 16 + intC
            // 每两个十六进制字母代表8位，即一个字节
            if index % 2 != 0 {
                bytes.append(UInt8(sum))
                sum = 0
            }
        }
        return bytes
    }
    
    private func hexStrToData(hexStr: String) -> Data {
        let bytes = hexStrToBytes(hexStr: hexStr)
        return Data(bytes: bytes, count: bytes.count)
    }
    
}

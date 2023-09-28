//
//  DeviceInfo.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/27.
//

import Foundation

class DeviceInfo: NSObject {
    var id:String = ""
    var name: String = ""
    var rssi: Int = 0
    init(id: String, name: String, rssi: Int) {
        self.id = id
        self.name = name
        self.rssi = rssi
        super.init()
    }
}

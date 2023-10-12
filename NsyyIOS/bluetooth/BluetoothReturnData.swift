//
//  BluetoothReturnData.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/8.
//

import Vapor

struct BluetoothReturnData: Content {
    let isSuccess: Bool
    let code: Int
    let errorMsg: String
    let data: [BluetoothDevice]
}

struct BluetoothDevice: Content {
    let id: String
    let name: String
    let macAddress: String
}

struct WeightReturn: Content {
    let res: String
    let code: Int
    let bag_weight: Double
}

//
//  NsyyConfig.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/24.
//

import Foundation

class NsyyConfig {

    static let NSYY_WEB_SERVER_PORT = 8081
    static let NSYY_YF_WEB_SERVER_PORT = 6079

    // 测试扫码功能
    static let TEST_CODE_SCAN_URL: String = "https://dnswc2-vue-demo.site.laf.dev/"

    // 南石医院 OA
    static let NSYY_URL: String = "http://oa.nsyy.com.cn:6060"
    
    // 南石医院 - 医废
    static let NSYY_YF_URL: String = "http://120.194.96.67:6060/index1.html?type=13#/"

    // 南石医院 - 医废 测试
    static let TEST_NSYY_YF_URL: String = "http://120.194.96.67:6060/index1.html?type=013#/"
    
    
    // settings bundle 配置标识符
    static let BLUETOOTH_CONFIG_IDENTIFIER: String = "mac_address"
    
    static let NSYY_CONFIG_IDENTIFIER: String = "selecter"
    
}

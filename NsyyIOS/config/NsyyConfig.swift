//
//  NsyyConfig.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/24.
//

import Vapor

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
    // 蓝牙秤 mac 地址
    static let BLUETOOTH_CONFIG_IDENTIFIER: String = "mac_address"
    
    // 选项
    static let NSYY_CONFIG_IDENTIFIER: String = "selecter"
    
    // 账户
    static let USERNAME_CONFIG_IDENTIFIER: String = "username"
    
    // 密码
    static let PASSWORD_CONFIG_IDENTIFIER: String = "password"
    
    
    
    func routes_config(_ app: Application) throws {
        // 查询用户信息
        app.get("user") { req async -> UserInfo in
            
            let username = UserDefaults.standard.value(forKey: NsyyConfig.USERNAME_CONFIG_IDENTIFIER) as? String
            let password = UserDefaults.standard.value(forKey: NsyyConfig.PASSWORD_CONFIG_IDENTIFIER) as? String
            
            if (username ?? "").isEmpty || (password ?? "").isEmpty {
                return UserInfo(hasValue: false, username: "", password: "")
            }

            return UserInfo(hasValue: true, username: username!, password: password!)
        }
        
        // 存储用户信息
        app.on(.POST, "user", body: .stream) { req -> ReturnData in
            let userInfo = try req.content.decode(UserInfo.self)
            print("save user info: username: \(userInfo.username) , password: \(userInfo.password)")
            if userInfo.username.isEmpty || userInfo.password.isEmpty {
                return ReturnData(isSuccess: false, code: 20001, errorMsg: "The user name and password can not be null", data: "")
            }
            
            UserDefaults.standard.set(userInfo.username, forKey: NsyyConfig.USERNAME_CONFIG_IDENTIFIER)
            UserDefaults.standard.set(userInfo.password, forKey: NsyyConfig.PASSWORD_CONFIG_IDENTIFIER)
            
            return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "User info saved successful")
        }
        
    }
    
}

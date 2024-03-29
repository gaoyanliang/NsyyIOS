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
    
    // 医体融合
    static let NSYY_SPORT_MNG_URL: String = "http://oa.nsyy.com.cn:6060/index99.html"
    
    
    // settings bundle 配置标识符
    // 蓝牙秤 mac 地址
    static let BLUETOOTH_CONFIG_IDENTIFIER: String = "mac_address"
    
    // 扫码枪名称
    static let SCAN_GUN_NAME_CONFIG_IDENTIFIER: String = "scan_gun_name"
    
    // 选项
    static let NSYY_CONFIG_IDENTIFIER: String = "selecter"
    
    // 账户
    static let USERNAME_CONFIG_IDENTIFIER: String = "username"
    
    // 密码
    static let PASSWORD_CONFIG_IDENTIFIER: String = "password"
    
    // 版本号
    static let VERSION_CONFIG_IDENTIFIER: String = "version"
    
    
    
    func routes_config(_ app: Application) throws {
        // 查询用户信息
        app.get("user") { req async -> UserInfo in
            
            let username = UserDefaults.standard.value(forKey: NsyyConfig.USERNAME_CONFIG_IDENTIFIER) as? String
            let password = UserDefaults.standard.value(forKey: NsyyConfig.PASSWORD_CONFIG_IDENTIFIER) as? String
            let version = UserDefaults.standard.value(forKey: NsyyConfig.VERSION_CONFIG_IDENTIFIER) as? String
            
            if (username ?? "").isEmpty || (password ?? "").isEmpty || (version ?? "").isEmpty {
                return UserInfo(hasValue: false, username: "", password: "", version: "")
            }
            
            let passw = password?.hexToString()

            return UserInfo(hasValue: true, username: username!, password: passw ?? "", version: version!)
        }
        
        // 存储用户信息
        app.on(.POST, "user", body: .stream) { req -> ReturnData in
            let userInfo = try req.content.decode(UserInfo.self)
            print("save user info: username: \(userInfo.username) , password: \(userInfo.password)")
            if userInfo.username.isEmpty || userInfo.password.isEmpty || userInfo.version.isEmpty {
                return ReturnData(isSuccess: false, code: 20001, errorMsg: "The user name, password, version can not be null", data: "")
            }
            
            let passw = userInfo.password.toHex()
            
            UserDefaults.standard.set(userInfo.username, forKey: NsyyConfig.USERNAME_CONFIG_IDENTIFIER)
            UserDefaults.standard.set(passw, forKey: NsyyConfig.PASSWORD_CONFIG_IDENTIFIER)
            UserDefaults.standard.set(userInfo.version, forKey: NsyyConfig.VERSION_CONFIG_IDENTIFIER)
            
            return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "User info saved successful")
        }
        
    }
    
}

extension String {
    func toHex() -> String {
        let hexString = self.utf8.map { String(format: "%02X", $0) }.joined()
        return hexString
    }
    
    func hexToString() -> String? {
        var hex = self
        var string = ""

        while hex.count > 0 {
            let index = hex.index(hex.startIndex, offsetBy: 2)
            let byte = hex[..<index]
            hex = String(hex[index...])

            if let value = UInt8(byte, radix: 16) {
                string.append(Character(UnicodeScalar(value)))
            } else {
                return nil
            }
        }

        return string
    }
}

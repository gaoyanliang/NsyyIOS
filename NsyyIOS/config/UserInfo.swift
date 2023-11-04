//
//  UserInfo.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/26.
//

import Vapor

struct UserInfo: Content {
    let hasValue: Bool
    let username: String
    let password: String
    let version: String
}

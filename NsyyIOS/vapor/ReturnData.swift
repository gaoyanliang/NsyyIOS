//
//  ReturnData.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/26.
//

import Vapor

struct ReturnData: Content {
    let isSuccess: Bool
    let code: Int
    let errorMsg: String
    let data: String
}

//
//  Notification.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/26.
//

import Vapor

final class Notification: Content {

    var title: String
    
    var context: String

    init(title: String, context: String) {
        self.title = title
        self.context = context
    }
}

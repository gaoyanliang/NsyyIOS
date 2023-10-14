//
//  Platform.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/14.
//

import Foundation

struct Platform {
    static let isSimulator: Bool = {
        #if swift(>=4.1)
          #if targetEnvironment(simulator)
            return true
          #else
            return false
          #endif
        #else
          #if (arch(i386) || arch(x86_64)) && os(iOS)
            return true
          #else
            return false
          #endif
        #endif
    }()
}

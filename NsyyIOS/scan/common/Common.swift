//
//  Common.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/14.
//

import Foundation
import UIKit

let bundle = Bundle(for: HeaderVC.self)

let screenWidth = UIScreen.main.bounds.width

let screenHeight = UIScreen.main.bounds.height

let statusHeight = UIApplication.shared.statusBarFrame.height

//if #available(iOS 13.0, *) {
//    let window = UIApplication.shared.windows.first(where: \.isKeyWindow)
//    statusBarHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
//} else {
//    statusBarHeight = UIApplication.shared.statusBarFrame.height
//}

public func imageNamed(_ name:String)-> UIImage{
    
    guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else{
        return UIImage()
    }
    
    return image
    
}

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

public func imageNamed(_ name:String)-> UIImage{
    
    guard let image = UIImage(named: name, in: bundle, compatibleWith: nil) else{
        return UIImage()
    }
    
    return image
    
}

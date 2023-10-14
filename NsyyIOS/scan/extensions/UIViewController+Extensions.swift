//
//  UIViewController+Extensions.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/14.
//

import Foundation
import UIKit

extension UIViewController{
    
    public func add(_ childController:UIViewController) {
        
        childController.willMove(toParent: self)
        
        addChild(childController)
        
        view.addSubview(childController.view)
        
        childController.didMove(toParent: self)
        
    }
    
    
}

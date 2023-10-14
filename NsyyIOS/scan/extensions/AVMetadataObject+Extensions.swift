//
//  AVMetadataObject+Extensions.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/14.
//

import Foundation
import AVFoundation

extension AVMetadataObject.ObjectType{
    
    public static let upca:AVMetadataObject.ObjectType = .init(rawValue: "org.gs1.UPC-A")
    
    /// `AVCaptureMetadataOutput` metadata object types.
    public static var metadata = [
        
        AVMetadataObject.ObjectType.aztec,
        
        AVMetadataObject.ObjectType.code128,
        
        AVMetadataObject.ObjectType.code39,
        
        AVMetadataObject.ObjectType.code39Mod43,
        
        AVMetadataObject.ObjectType.code93,
        
        AVMetadataObject.ObjectType.dataMatrix,
        
        AVMetadataObject.ObjectType.ean13,
        
        AVMetadataObject.ObjectType.ean8,
        
        AVMetadataObject.ObjectType.face,
        
        AVMetadataObject.ObjectType.interleaved2of5,
        
        AVMetadataObject.ObjectType.itf14,
        
        AVMetadataObject.ObjectType.pdf417,
        
        AVMetadataObject.ObjectType.qr,
        
        AVMetadataObject.ObjectType.upce
        
    ]
    
}

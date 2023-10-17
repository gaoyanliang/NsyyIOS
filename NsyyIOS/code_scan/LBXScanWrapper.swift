//
//  LBXScanWrapper.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/16.
//

import UIKit
import AVFoundation

public struct LBXScanResult {
    
    /// 码内容
    public var strScanned: String?
    
    /// 码的类型
    public var strBarCodeType: String?

    public init(str: String?, barCodeType: String?) {
        strScanned = str
        strBarCodeType = barCodeType
    }
}



open class LBXScanWrapper: NSObject,AVCaptureMetadataOutputObjectsDelegate {
    
    let device = AVCaptureDevice.default(for: AVMediaType.video)
    var input: AVCaptureDeviceInput?
    var output: AVCaptureMetadataOutput

    let session = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer?
    var stillImageOutput: AVCaptureStillImageOutput

    // 存储返回结果
    var arrayResult = [LBXScanResult]()

    // 扫码结果返回block
    var successBlock: ([LBXScanResult]) -> Void

    // 当前扫码结果是否处理
    var isNeedScanResult = true
    
    //连续扫码
    var supportContinuous = false
    
    
    /**
     初始化设备
     - parameter videoPreView: 视频显示UIView
     - parameter objType:      识别码的类型,缺省值 QR二维码
     - parameter cropRect:     识别区域
     - parameter success:      返回识别信息
     - returns:
     */
    init(videoPreView: UIView,
         objType: [AVMetadataObject.ObjectType] = [(AVMetadataObject.ObjectType.qr as NSString) as AVMetadataObject.ObjectType],
         cropRect: CGRect = .zero,
         success: @escaping (([LBXScanResult]) -> Void)) {
        
        successBlock = success
        output = AVCaptureMetadataOutput()
        stillImageOutput = AVCaptureStillImageOutput()

        super.init()
        
        guard let device = device else {
            return
        }
        do {
            input = try AVCaptureDeviceInput(device: device)
        } catch let error as NSError {
            print("AVCaptureDeviceInput(): \(error)")
        }
        guard let input = input else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }

        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        if session.canAddOutput(stillImageOutput) {
            session.addOutput(stillImageOutput)
        }

        stillImageOutput.outputSettings = [AVVideoCodecJPEG: AVVideoCodecKey]

        session.sessionPreset = AVCaptureSession.Preset.high

        // 参数设置
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)

        output.metadataObjectTypes = objType

        //        output.metadataObjectTypes = [AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code]

        if !cropRect.equalTo(CGRect.zero) {
            // 启动相机后，直接修改该参数无效
            output.rectOfInterest = cropRect
        }

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill

        var frame: CGRect = videoPreView.frame
        frame.origin = CGPoint.zero
        previewLayer?.frame = frame

        videoPreView.layer.insertSublayer(previewLayer!, at: 0)

        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.continuousAutoFocus) {
            do {
                try input.device.lockForConfiguration()
                input.device.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
                input.device.unlockForConfiguration()
            } catch let error as NSError {
                print("device.lockForConfiguration(): \(error)")
            }
        }
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        captureOutput(output, didOutputMetadataObjects: metadataObjects, from: connection)
    }
    
    func start() {
        if !session.isRunning {
            isNeedScanResult = true
            session.startRunning()
        }
    }
    
    func stop() {
        if session.isRunning {
            isNeedScanResult = false
            session.stopRunning()
        }
    }
    
    open func captureOutput(_ captureOutput: AVCaptureOutput,
                            didOutputMetadataObjects metadataObjects: [Any],
                            from connection: AVCaptureConnection!) {
        guard isNeedScanResult else {
            // 上一帧处理中
            return
        }
        isNeedScanResult = false

        arrayResult.removeAll()

        // 识别扫码类型
        for current in metadataObjects {
            guard let code = current as? AVMetadataMachineReadableCodeObject else {
                continue
            }
            
            #if !targetEnvironment(simulator)
            
            arrayResult.append(LBXScanResult(str: code.stringValue,
                                             barCodeType: code.type.rawValue))
            #endif
        }

        if arrayResult.isEmpty || supportContinuous {
            isNeedScanResult = true
        }
        if !arrayResult.isEmpty {
            
            if supportContinuous {
                successBlock(arrayResult)
            } else {
                stop()
                successBlock(arrayResult)
            }
        }
    }
    
    //MARK: ----拍照
    open func captureImage() {
        guard let stillImageConnection = connectionWithMediaType(mediaType: AVMediaType.video as AVMediaType,
                                                                 connections: stillImageOutput.connections as [AnyObject]) else {
                                                                    return
        }
        stillImageOutput.captureStillImageAsynchronously(from: stillImageConnection, completionHandler: { (imageDataSampleBuffer, _) -> Void in
            self.stop()
//            if let imageDataSampleBuffer = imageDataSampleBuffer,
//                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageDataSampleBuffer) {
//                
//                let scanImg = UIImage(data: imageData)
//                for idx in 0 ... self.arrayResult.count - 1 {
//                    self.arrayResult[idx].imgScanned = scanImg
//                }
//            }
            self.successBlock(self.arrayResult)
        })
    }
    
    open func connectionWithMediaType(mediaType: AVMediaType, connections: [AnyObject]) -> AVCaptureConnection? {
        for connection in connections {
            guard let connectionTmp = connection as? AVCaptureConnection else {
                continue
            }
            for port in connectionTmp.inputPorts where port.mediaType == mediaType {
                return connectionTmp
            }
        }
        return nil
    }
    
    
    //MARK: 切换识别区域

    open func changeScanRect(cropRect: CGRect) {
        // 待测试，不知道是否有效
        stop()
        output.rectOfInterest = cropRect
        start()
    }

    //MARK: 切换识别码的类型
    open func changeScanType(objType: [AVMetadataObject.ObjectType]) {
        // 待测试中途修改是否有效
        output.metadataObjectTypes = objType
    }
    
    open func isGetFlash() -> Bool {
        return device != nil && device!.hasFlash && device!.hasTorch
    }
    
    /**
     打开或关闭闪关灯
     - parameter torch: true：打开闪关灯 false:关闭闪光灯
     */
    open func setTorch(torch: Bool) {
        guard isGetFlash() else {
            return
        }
        do {
            try input?.device.lockForConfiguration()
            input?.device.torchMode = torch ? AVCaptureDevice.TorchMode.on : AVCaptureDevice.TorchMode.off
            input?.device.unlockForConfiguration()
        } catch let error as NSError {
            print("device.lockForConfiguration(): \(error)")
        }
    }
    
    
    /// 闪光灯打开或关闭
    open func changeTorch() {
        let torch = input?.device.torchMode == .off
        setTorch(torch: torch)
    }
    
    //MARK: ------获取系统默认支持的码的类型
    static func defaultMetaDataObjectTypes() -> [AVMetadataObject.ObjectType] {
        var types =
            [
                AVMetadataObject.ObjectType.qr,
                AVMetadataObject.ObjectType.upce,
                AVMetadataObject.ObjectType.code39,
                AVMetadataObject.ObjectType.code39Mod43,
                AVMetadataObject.ObjectType.ean13,
                AVMetadataObject.ObjectType.ean8,
                AVMetadataObject.ObjectType.code93,
                AVMetadataObject.ObjectType.code128,
                AVMetadataObject.ObjectType.pdf417,
                AVMetadataObject.ObjectType.aztec,
            ]
        // if #available(iOS 8.0, *)

        types.append(AVMetadataObject.ObjectType.interleaved2of5)
        types.append(AVMetadataObject.ObjectType.itf14)
        types.append(AVMetadataObject.ObjectType.dataMatrix)
        return types
    }
    
    /**
     识别二维码码图像
     - parameter image: 二维码图像
     - returns: 返回识别结果
     */
    public static func recognizeQRImage(image: UIImage) -> [LBXScanResult] {
        print("\(#function) 识别图片中的二维码")
        guard let cgImage = image.cgImage else {
            return []
        }
        let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
        let img = CIImage(cgImage: cgImage)
        let features = detector.features(in: img, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        return features.filter {
            $0.isKind(of: CIQRCodeFeature.self)
        }.map {
            $0 as! CIQRCodeFeature
        }.map {
            LBXScanResult(str: $0.messageString,
                          barCodeType: AVMetadataObject.ObjectType.qr.rawValue)
        }
    }
    
    
    // 根据二维码的区域截取二维码区域图像
    public static func getConcreteCodeImage(srcCodeImage: UIImage, rect: CGRect) -> UIImage? {
        guard !rect.isEmpty, let img = imageByCroppingWithStyle(srcImg: srcCodeImage, rect: rect) else {
            return nil
        }
        return imageRotation(image: img, orientation: UIImage.Orientation.right)
    }

    
    //MARK: ----图像处理
    
    /**

    @brief  图像中间加logo图片
    @param srcImg    原图像
    @param LogoImage logo图像
    @param logoSize  logo图像尺寸
    @return 加Logo的图像
    */
    public static func addImageLogo(srcImg: UIImage, logoImg: UIImage, logoSize: CGSize) -> UIImage {
        UIGraphicsBeginImageContext(srcImg.size)
        srcImg.draw(in: CGRect(x: 0, y: 0, width: srcImg.size.width, height: srcImg.size.height))
        let rect = CGRect(x: srcImg.size.width / 2 - logoSize.width / 2,
                          y: srcImg.size.height / 2 - logoSize.height / 2,
                          width: logoSize.width,
                          height: logoSize.height)
        logoImg.draw(in: rect)
        let resultingImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resultingImage!
    }
    
    //图像缩放
    static func resizeImage(image: UIImage, quality: CGInterpolationQuality, rate: CGFloat) -> UIImage? {
        var resized: UIImage?
        let width = image.size.width * rate
        let height = image.size.height * rate

        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        let context = UIGraphicsGetCurrentContext()
        context?.interpolationQuality = quality
        image.draw(in: CGRect(x: 0, y: 0, width: width, height: height))

        resized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resized
    }

    // 图像裁剪
    static func imageByCroppingWithStyle(srcImg: UIImage, rect: CGRect) -> UIImage? {
        guard let imagePartRef = srcImg.cgImage?.cropping(to: rect) else {
            return nil
        }
        return UIImage(cgImage: imagePartRef)
    }
    
    // 图像旋转
    static func imageRotation(image: UIImage, orientation: UIImage.Orientation) -> UIImage {
        var rotate: Double = 0.0
        var rect: CGRect
        var translateX: CGFloat = 0.0
        var translateY: CGFloat = 0.0
        var scaleX: CGFloat = 1.0
        var scaleY: CGFloat = 1.0

        switch orientation {
        case .left:
            rotate = .pi / 2
            rect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
            translateX = 0
            translateY = -rect.size.width
            scaleY = rect.size.width / rect.size.height
            scaleX = rect.size.height / rect.size.width
        case .right:
            rotate = 3 * .pi / 2
            rect = CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width)
            translateX = -rect.size.height
            translateY = 0
            scaleY = rect.size.width / rect.size.height
            scaleX = rect.size.height / rect.size.width
        case .down:
            rotate = .pi
            rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            translateX = -rect.size.width
            translateY = -rect.size.height
        default:
            rotate = 0.0
            rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            translateX = 0
            translateY = 0
        }

        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        // 做CTM变换
        context.translateBy(x: 0.0, y: rect.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.rotate(by: CGFloat(rotate))
        context.translateBy(x: translateX, y: translateY)

        context.scaleBy(x: scaleX, y: scaleY)
        // 绘制图片
        context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: rect.size.width, height: rect.size.height))
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
    
}

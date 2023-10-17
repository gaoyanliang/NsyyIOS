//
//  LBXScanViewController.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/16.
//

import UIKit
import Foundation
import AVFoundation

public protocol LBXScanViewControllerDelegate: class {
     func scanFinished(scanResult: LBXScanResult, error: String?)
}

public protocol QRRectDelegate {
    func drawwed()
}

open class LBXScanViewController: UIViewController {
    
    // 返回扫码结果，也可以通过继承本控制器，改写该handleCodeResult方法即可
    open weak var scanResultDelegate: LBXScanViewControllerDelegate?

    open var scanObj: LBXScanWrapper?

    open var scanStyle: LBXScanViewStyle? = LBXScanViewStyle()

    open var qRScanView: LBXScanView?

    // 启动区域识别功能
    open var isOpenInterestRect = true
    
    //连续扫码
    open var isSupportContinuous = false;

    // 识别码的类型
    public var arrayCodeType: [AVMetadataObject.ObjectType]?

    // 相机启动提示文字
    public var readyString: String! = "loading"

    open override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        edgesForExtendedLayout = UIRectEdge(rawValue: 0)
    }

    // 设置框内识别
    open func setOpenInterestRect(isOpen: Bool) {
        isOpenInterestRect = isOpen
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawScanView()
        perform(#selector(LBXScanViewController.startScan), with: nil, afterDelay: 0.3)
    }
    
    
    @objc open func startScan() {
        if scanObj == nil {
            var cropRect = CGRect.zero
            if isOpenInterestRect {
                cropRect = LBXScanView.getScanRectWithPreView(preView: view, style: scanStyle!)
            }

            // 指定识别几种码
            if arrayCodeType == nil {
                arrayCodeType = [AVMetadataObject.ObjectType.qr as NSString,
                                 AVMetadataObject.ObjectType.ean13 as NSString,
                                 AVMetadataObject.ObjectType.code128 as NSString] as [AVMetadataObject.ObjectType]
            }

            scanObj = LBXScanWrapper(videoPreView: view,
                                     objType: arrayCodeType!,
                                     cropRect: cropRect,
                                     success: { [weak self] (arrayResult) -> Void in
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        if !strongSelf.isSupportContinuous {
                                            // 停止扫描动画
                                            strongSelf.qRScanView?.stopScanAnimation()
                                        }
                                        strongSelf.handleCodeResult(arrayResult: arrayResult)
                                     })
        }
        
        scanObj?.supportContinuous = isSupportContinuous;

//        // 结束相机等待提示
//        qRScanView?.deviceStopReadying()

        // 开始扫描动画
        qRScanView?.startScanAnimation()

        // 相机运行
        scanObj?.start()
    }
    
    open func drawScanView() {
        if qRScanView == nil {
            qRScanView = LBXScanView(frame: view.frame, bounds: view.bounds, vstyle: scanStyle!)
            view.addSubview(qRScanView!)
        }
        //qRScanView!.deviceStartReadying(readyStr: readyString)
        
        qRScanView!.translatesAutoresizingMaskIntoConstraints = false
        // 定位到 view 底部 中间
        NSLayoutConstraint.activate([
            // Set the view's width and height
            qRScanView!.widthAnchor.constraint(equalToConstant: view.frame.size.width - 30),
            qRScanView!.heightAnchor.constraint(equalToConstant: view.frame.size.width - 30),

            // Center the view horizontally and vertically
            qRScanView!.centerYAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 100),

            qRScanView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            qRScanView!.topAnchor.constraint(equalTo: view.topAnchor)
        ])
    }
   

    /**
     处理扫码结果，如果是继承本控制器的，可以重写该方法,作出相应地处理，或者设置delegate作出相应处理
     */
    open func handleCodeResult(arrayResult: [LBXScanResult]) {
        self.dismiss(animated: true, completion: nil)
        guard let delegate = scanResultDelegate else {
            fatalError("you must set scanResultDelegate or override this method without super keyword")
        }
        
        if !isSupportContinuous {
            dismiss(animated: true, completion: nil)
            //navigationController?.popViewController(animated: true)
        }
        
        if let result = arrayResult.first {
            delegate.scanFinished(scanResult: result, error: nil)
        } else {
            let result = LBXScanResult(str: nil, barCodeType: nil)
            delegate.scanFinished(scanResult: result, error: "no scan result")
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        qRScanView?.stopScanAnimation()
        scanObj?.stop()
    }

    
    
    
}

//MARK: - 图片选择代理方法
extension LBXScanViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //MARK: -----相册选择图片识别二维码 （条形码没有找到系统方法）
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        print("\(#function) 从相册选择图片")
        picker.dismiss(animated: true, completion: nil)
        
        let editedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        let originalImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        guard let image = editedImage ?? originalImage else {
            //showMsg(title: nil, message: NSLocalizedString("Identify failed", comment: "Identify failed"))
            
            print("\(#function) ===> showMsg: Identify failed")
            
            return
        }
        let arrayResult = LBXScanWrapper.recognizeQRImage(image: image)
        
        if !arrayResult.isEmpty {
            //scanFinished(scanResult: arrayResult[0], error: nil)
            handleCodeResult(arrayResult: arrayResult)
        }
    }
    
}

//MARK: - 私有方法
private extension LBXScanViewController {
    
    func showMsg(title: String?, message: String?) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
}

//
//  ScanController.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/12.
//

import UIKit
import AVFoundation

class QRScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, CAAnimationDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // 输入输出中间桥梁
    var session: AVCaptureSession?
    var layer: AVCaptureVideoPreviewLayer?
    var maskView: UIView?
    var scanLineView: UIImageView?
    
    var orginalStyle: UIStatusBarStyle = .default
    
    var hud: ProgressView?
    var isFirstAppear: Bool = true
    
    // 提示将二维码放入框内label
    var textLabel: UILabel?
    // 手电筒按钮
    var torchBtn: UIButton?
    // 轻触照亮 / 关闭
    var tipLabel: UILabel?
    // 光线第一次变暗
    var isFirstBecomeDark: Bool = true
    // 最后亮度值
    var lastBrightnessValue: Float = 0.0
    
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    // 屏幕尺寸
    var screenHeight: Double = 0.0
    var screenWidth: Double = 0.0

    // TODO: 是否使用 dealloc
    func dealloc() {
        NotificationCenter.default.removeObserver(self)
        session?.stopRunning()
        switchTorch(false)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black
        isFirstAppear = true
        isFirstBecomeDark = true
        hud = ProgressView()
        hud?.show(view: self.view)
        NotificationCenter.default.addObserver(self, selector: #selector(initScanUI), name: UIApplication.willEnterForegroundNotification, object: nil)
        initBaseUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let scanLineView = scanLineView {
            scanLineView.removeFromSuperview()
            self.scanLineView = nil
        }
        orginalStyle = UIApplication.shared.statusBarStyle
        UIApplication.shared.statusBarStyle = .lightContent
        navigationController?.isNavigationBarHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isFirstAppear {
            initScanLineView()
            session?.startRunning()
            return
        }
        initScanUI()
        initScan()
        hud?.hide()
        isFirstAppear = false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.statusBarStyle = orginalStyle
        navigationController?.isNavigationBarHidden = false
    }

    
    // MARK: 初始化
    func initBaseUI() {
        
        self.screenWidth = UIScreen.main.bounds.size.width
        self.screenHeight = UIScreen.main.bounds.size.height
        
        
        let btn = UIButton(type: .custom)
        
        btn.frame = CGRect(x: 15, y: 27, width: 30, height: 30)
        btn.setImage(UIImage(named: "ic_back.png"), for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.addTarget(self, action: #selector(btnBack), for: .touchUpInside)
        view.addSubview(btn)

        let label = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - 30, y: 27, width: 60, height: 30))
        label.textColor = .white
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = "扫一扫"
        view.addSubview(label)

        let pathWidth = UIScreen.main.bounds.size.width - 100
        let orginY = (UIScreen.main.bounds.size.height - pathWidth) / 2 - 50 + pathWidth

        textLabel = UILabel(frame: CGRect(x: 50, y: orginY + 15, width: pathWidth, height: 20))
        textLabel?.text = "将二维码放入框内，即可自动扫描"
        textLabel?.textAlignment = .center
        textLabel?.font = UIFont.systemFont(ofSize: 14)
        textLabel?.textColor = UIColor(white: 0.7, alpha: 1)
        view.addSubview(textLabel!)

        torchBtn = UIButton(type: .custom)
        torchBtn?.frame = CGRect(x: UIScreen.main.bounds.size.width/2 - 15, y: orginY + 40, width: 30, height: 30)
        torchBtn?.isHidden = true
        torchBtn?.setImage(UIImage(named: "torch_n"), for: .normal)
        torchBtn?.setImage(UIImage(named: "torch_s"), for: .selected)
        torchBtn?.addTarget(self, action: #selector(switchTorchClick), for: .touchUpInside)
        view.addSubview(torchBtn!)

        tipLabel = UILabel(frame: CGRect(x: UIScreen.main.bounds.size.width/2 - 50, y: orginY + 75, width: 100, height: 30))
        tipLabel?.isHidden = true
        tipLabel?.text = "轻触照亮"
        tipLabel?.textAlignment = .center
        tipLabel?.font = UIFont.systemFont(ofSize: 14)
        tipLabel?.textColor = .white
        view.addSubview(tipLabel!)
    }

    @objc func initScanUI() {
        maskView = UIView(frame: view.bounds)
        maskView?.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(maskView!)
        view.sendSubviewToBack(maskView!)

        let pathWidth = UIScreen.main.bounds.size.width - 150
        let orginY = (UIScreen.main.bounds.size.height - pathWidth) / 2 - 50
        let imageView = UIImageView(image: UIImage(named: "ic_scanBg.png"))
        imageView.frame = CGRect(x: 50, y: orginY, width: pathWidth, height: pathWidth)
        view.addSubview(imageView)

        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.duration = 0.25
        animation.fromValue = 0
        animation.toValue = 1
        animation.delegate = self
        imageView.layer.add(animation, forKey: nil)
    }

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        let maskLayer = CAShapeLayer()
        let path = CGMutablePath()
        let pathWidth = UIScreen.main.bounds.size.width - 100
        let orginY = (UIScreen.main.bounds.size.height - pathWidth) / 2 - 50

//        CGPathAddRect(path, nil, CGRect(x: 50, y: orginY, width: pathWidth, height: pathWidth))
//        CGPathAddRect(path, nil, maskView!.bounds)
        maskLayer.fillRule = .evenOdd
        maskLayer.path = path
        maskView?.layer.mask = maskLayer
        initScanLineView()
    }

    func initScanLineView() {
        let pathWidth = UIScreen.main.bounds.size.width - 100
        let orginY = (UIScreen.main.bounds.size.height - pathWidth) / 2 - 50

        if let scanLineView = scanLineView {
            scanLineView.removeFromSuperview()
            self.scanLineView = nil
        }

        scanLineView = UIImageView(image: UIImage(named: "ic_scanLine.png"))
        var frame = CGRect(x: 55, y: orginY, width: pathWidth - 10, height: 5)
        scanLineView?.frame = frame
        frame.origin.y += pathWidth - 5
        UIView.animate(withDuration: 4.0, delay: 0.2, options: [.repeat, .allowUserInteraction, .curveLinear], animations: {
            self.scanLineView?.frame = frame
        }, completion: nil)
        view.addSubview(scanLineView!)
    }

    @objc func btnBack() {
        if let vc = navigationController?.popViewController(animated: true) {
            // Pop succeeded, do nothing
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    // Rest of the code for scan, light sensing, and torch functions...
    

    func requestAuth() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        print("status is: \(status.rawValue)")
        
        if status == .denied {
            let alert = UIAlertController(title: "", message: "请在设置->隐私中允许该软件访问摄像头", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        
        if status == .restricted {
            let alert = UIAlertController(title: "", message: "设备不支持", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            let alert = UIAlertController(title: "", message: "模拟器不支持该功能", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return false
        }
        
        return true
    }
    
    func initScan() {
        let canInit = requestAuth()
        if !canInit {
            return
        }
        
        //获取摄像设备
        if let device = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                let output = AVCaptureMetadataOutput()
                //设置扫描有效区域
                /*
                 1、这个CGRect参数和普通的Rect范围不太一样，它的四个值的范围都是0-1，表示比例。
                 2、经过测试发现，这个参数里面的x对应的恰恰是距离左上角的垂直距离，y对应的是距离左上角的水平距离。
                 3、宽度和高度设置的情况也是类似。
                 3、举个例子如果我们想让扫描的处理区域是屏幕的下半部分，我们这样设置
                 output.rectOfInterest = CGRectMake(0.5, 0, 0.5, 1);
                 */
                
                output.rectOfInterest = CGRect(x: 0.1, y: 0.2, width: 0.5, height: 0.5)
                output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                //设置光感代理输出
                let respondOutput = AVCaptureVideoDataOutput()
                respondOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
                
                if let session = session {
                    session.stopRunning()
                }
                session = AVCaptureSession()
                session?.sessionPreset = .high
                
                if let session = session {
                    if session.canAddInput(input) {
                        session.addInput(input)
                    }
                    if session.canAddOutput(output) {
                        session.addOutput(output)
                    }
                    if session.canAddOutput(respondOutput) {
                        session.addOutput(respondOutput)
                    }
                }
                
                //设置扫码支持的编码格式
                output.metadataObjectTypes = [
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
                
                if let session = session {
                    layer = AVCaptureVideoPreviewLayer(session: session)
                    layer?.videoGravity = .resizeAspectFill
                    if let layer = layer {
                        layer.frame = view.frame
                        view.layer.insertSublayer(layer, at: 0)
                    }
                    session.startRunning()
                }
            } catch {
                print("Error initializing AVCaptureDeviceInput: \(error.localizedDescription)")
            }
        }
    }
    
    // 光感回调
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let metadataDict = CMCopyDictionaryOfAttachments(allocator: kCFAllocatorDefault, target: sampleBuffer, attachmentMode: kCMAttachmentMode_ShouldPropagate) {
            let metadata = NSMutableDictionary(dictionary: metadataDict as NSDictionary)
            // CFRelease(metadataDict)
//            if let exifMetadata = (metadata[kCGImagePropertyExifDictionary as String] as? NSDictionary)?.mutableCopy() {
//                if let brightnessValue = exifMetadata[kCGImagePropertyExifBrightnessValue as String] as? Float {
//                    if (lastBrightnessValue > 0 && brightnessValue > 0) || (lastBrightnessValue <= 0 && brightnessValue <= 0) {
//                        return
//                    }
//                    lastBrightnessValue = brightnessValue
//                    switchTorchBtnState(brightnessValue <= 0)
//                }
//            }
        }
    }
    
    
    // 扫描结果回调
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutputMetadataObjects metadataObjects: [Any], fromConnection connection: AVCaptureConnection) {
        
        for metadataObject in metadataObjects {
            if let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let stringValue = readableObject.stringValue {
                
                print("\(#function) Code is successfully scanned \(stringValue)")
                
            }
        }
        
//        if metadataObjects.count > 0 {
//            session?.stopRunning()
//            if let metaDataObject = metadataObjects[0] as? AVMetadataMachineReadableCodeObject {
//                switchTorch(false)
//                if let delegate = delegate, delegate.responds(to: #selector(qrScanResult(viewController:))) {
//                    delegate.perform(#selector(qrScanResult(viewController:)), with: metaDataObject.stringValue, with: self)
//                }
//            }
//        }
    }
    
    @objc func switchTorchClick(_ btn: UIButton) {
        switchTorch(!btn.isSelected)
    }

    func switchTorch(_ on: Bool) {
        torchBtn!.isSelected = on
        tipLabel!.text = "轻触\(on ? "关闭" : "照亮")"
        
        if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
            do {
                try device.lockForConfiguration()
                if on {
                    device.torchMode = .on
                } else if device.torchMode == .on {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Error toggling torch: \(error.localizedDescription)")
            }
        }
    }
    
    
    func switchTorchBtnState(_ show: Bool) {
        torchBtn!.isHidden = !show && !torchBtn!.isSelected
        tipLabel!.isHidden = !show && !torchBtn!.isSelected
        textLabel!.isHidden = show || torchBtn!.isSelected
        
        if show {
            scanLineView!.removeFromSuperview()
            if isFirstBecomeDark {
                let animate = CABasicAnimation(keyPath: "opacity")
                animate.fromValue = 1
                animate.toValue = 0
                animate.duration = 0.6
                animate.repeatCount = 2
                torchBtn!.layer.add(animate, forKey: nil)
                isFirstBecomeDark = false
            }
        } else {
            initScanLineView()
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

class ProgressView: UIView {
    private var indictor: UIActivityIndicatorView = UIActivityIndicatorView()
    private var textLabel: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initUI()
    }
    
    private func initUI() {
        self.frame = CGRect(x: UIScreen.main.bounds.size.width/2 - 50, y: UIScreen.main.bounds.size.height/2 - 50, width: 100, height: 100)
        
        indictor.style = .whiteLarge
        indictor.center = CGPoint(x: 50, y: 50)
        indictor.hidesWhenStopped = true
        addSubview(indictor)
        
        textLabel.frame = CGRect(x: 0, y: self.frame.size.height - 20, width: self.frame.size.width, height: 20)
        textLabel.text = "正在加载..."
        textLabel.font = UIFont.systemFont(ofSize: 14)
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.white
        addSubview(textLabel)
    }
    
    func show(view: UIView) {
        indictor.startAnimating()
        view.addSubview(self)
    }
    
    func hide() {
        indictor.stopAnimating()
        removeFromSuperview()
    }
}


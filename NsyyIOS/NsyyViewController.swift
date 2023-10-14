//
//  ViewController.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/9/22.
//

import UIKit
import WebKit
import CoreLocation
import Vapor
import AVFoundation

// 注意： 要想正常加载指定 URL 需要在 info.plist 中配置 App Transport Security Settings - Allow Arbitrary Loads = true
class NsyyViewController: UIViewController, WKScriptMessageHandler, AVCaptureMetadataOutputObjectsDelegate {
    
    // 测试扫码功能
    private let urlString: String = "https://dnswc2-vue-demo.site.laf.dev/"

    // 南石医院 OA
    //private let urlString: String = "http://oa.nsyy.com.cn:6060"
    
    // 南石医院 - 医废
    //private let urlString: String = "http://120.194.96.67:6060/index1.html?type=13#/"

    // 南石医院 - 医废 测试
    //private let urlString: String = "http://120.194.96.67:6060/index1.html?type=013#/"
    
    // Create an AVCaptureSession and AVCaptureVideoPreviewLayer
    let captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var webView: WKWebView!
    var result: String!
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 适当的时机 移除 WKScriptMessageHandler 防止引用循环
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "scanCode")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the WKUserContentController to handle JavaScript messages
        let contentController = WKUserContentController()
        contentController.add(self, name: "scanCode")
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        
        
        webConfiguration.preferences = WKPreferences()
        webConfiguration.preferences.minimumFontSize = 0
        webConfiguration.preferences.javaScriptEnabled = true
        webConfiguration.processPool = WKProcessPool()
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true


        webView = WKWebView(frame: view.bounds, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
        
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        

        if message.name == "scanCode" {
            // Call your code scanning function here
            // This function should communicate with your code scanning library
            // and then send the result back to JavaScript
            print("\(#function) 执行 \(message.name)")
            scanCodeAndSendResultToJS()
            //btnScanClick()
        }
    }
    
//    func btnScanClick() {
//        
//        let vc = ScannerVC()
//        //默认(push)
//        vc.setupScanner { (code) in
//            
//            print(code)
//            
//            self.receiveScanReturn(code: code)
//            
//            // 扫描成功，关闭扫描页面
//            self.dismiss(animated: true, completion: nil)
//        }
//        
//        // 弹出扫码页面
//        present(vc, animated: true, completion: nil)
//        
////        let vc = QRScanViewController()
////        vc.delegate = self
////        vc.hidesBottomBarWhenPushed = true
////        show(vc, sender: nil)
//    }
    
    
//    func receiveScanReturn(code: String) {
//        
//        let jsCode = "receiveScanResult('\(code)');"
//        print("\(#function) 调用 js 方法 \(jsCode)")
//
//        webView.evaluateJavaScript(jsCode, completionHandler: { (result, error) in
//            if let error = error {
//                print("Error calling JavaScript function: \(error)")
//            } else if let result = result {
//                print("JavaScript result: \(result)")
//            }
//        })
//    }
//    
    
    func scanCodeAndSendResultToJS() {
        print("\(#function) 开始扫码")
        setupScanner()
        
        // Implement your code scanning logic here
        guard let videoPreviewLayer = videoPreviewLayer else { return }

        let captureMetadataOutput = captureSession.outputs.first as? AVCaptureMetadataOutput
        captureMetadataOutput?.rectOfInterest = videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: videoPreviewLayer.bounds)

        captureSession.startRunning()
    }
    
    
    func setupScanner() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            print("Failed to get the camera device")
            return
        }
        
        do {
            // 在添加新的 input 之前，先删除旧的
            if let inputs = captureSession.inputs as? [AVCaptureDeviceInput] {
                for input in inputs {
                    captureSession.removeInput(input)
                }
            }
            
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print("Error setting up AVCaptureDeviceInput: \(error)")
            return
        }
    
        
        // 在添加新的 output 之前，先删除旧的
        if let outputs = captureSession.outputs as? [AVCaptureMetadataOutput] {
            for output in outputs {
                captureSession.removeOutput(output)
            }
        }
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        
        /// `AVCaptureMetadataOutput` metadata object types.
        let metadata = [
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
        
        captureMetadataOutput.metadataObjectTypes = metadata

        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer)
        
        // Start the capture session
        captureSession.startRunning()
    }
    
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        for metadataObject in metadataObjects {
            if let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
               let stringValue = readableObject.stringValue {
                
                print("\(#function) Code is successfully scanned \(stringValue)")
                
                // Code is successfully scanned
                captureSession.stopRunning()
                // 扫描之后退出详解
                videoPreviewLayer.removeFromSuperlayer()
                
                // Send the result back to JavaScript
                self.result = stringValue
                let jsCode = "receiveScanResult('\(stringValue)');"
                print("\(#function) 调用 js 方法 \(jsCode)")

                webView.evaluateJavaScript(jsCode, completionHandler: { (result, error) in
                    if let error = error {
                        print("Error calling JavaScript function: \(error)")
                    } else if let result = result {
                        print("JavaScript result: \(result)")
                    }
                })
    
            }
        }
    }

    

    
    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // 加载南石医院 OA 系统
//        loadNsyyView()
//    }
//    
//    // 加载南石医院 oa 页面
//    func loadNsyyView() {
//        // Initialize WKWebView
//        webView = WKWebView(frame: view.frame)
//        webView.navigationDelegate = self
//        
//        // 允许左滑右滑，默认值为NO；设置为YES后，即可实现左右滑手势可用。
//        webView.allowsBackForwardNavigationGestures = true
//        
//        view.addSubview(webView)
//
//        // Load a URL
//        let url = URL(string: urlString)
//        let request = URLRequest(url: url!)
//        webView.load(request)
//    }
}


// MARK: - web view 页面加载状态响应
extension NsyyViewController: WKNavigationDelegate {

    // 页面开始加载时调用（开始请求服务器，并加载页面）
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!){
        print("\(#function) 网页开始加载...\(String(describing: webView.url))")
    }

    // 当内容开始返回时调用(开始渲染页面时调用，响应的内容到达主页面的时候响应,刚准备开始渲染页面)
    func webView(_ webview: WKWebView, didCommit navigation: WKNavigation!) {
        print("\(#function) 开始渲染页面")
    }

    // 页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("\(#function) 网页加载成功 🎉")
    }
    
    // 页面加载失败时调用
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("\(#function) 网页加载失败: \(error.localizedDescription)")
    }
}


// MARK: - WKUIDelegate javascript alert  https://www.jianshu.com/p/e4c274248a78
extension NsyyViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "确认", style: .default) { _ in
            completionHandler()
        })
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "取消", style: .cancel) { _ in
            completionHandler(false)
        })
        alertController.addAction(UIAlertAction(title: "确认", style: .default) { _ in
            completionHandler(true)
        })
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alertController = UIAlertController(title: prompt, message: "", preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.text = defaultText
        }
        alertController.addAction(UIAlertAction(title: "完成", style: .default) { _ in
            completionHandler(alertController.textFields?.first?.text ?? "")
        })
        present(alertController, animated: true, completion: nil)
    }
    
}

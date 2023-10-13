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
class NsyyViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler, AVCaptureMetadataOutputObjectsDelegate {
    
    //private let urlString: String = "http://localhost:5173/"
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up the WKUserContentController to handle JavaScript messages
        let contentController = WKUserContentController()
        contentController.add(self, name: "scanCode")

        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
        
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        webView.load(request)
    }
    
    // Implement the WKScriptMessageHandler method to handle JavaScript messages
    @objc(userContentController:didReceiveScriptMessage:) func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        print("\(#function) 被调用 \(message.name) \(message.description)")
        
        if message.name == "scanCode" {
            // Call your code scanning function here
            // This function should communicate with your code scanning library
            // and then send the result back to JavaScript
            scanCodeAndSendResultToJS()
        }
    }
    
    func scanCodeAndSendResultToJS() {
        print("\(#function) 被调用")
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
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print("Error setting up AVCaptureDeviceInput: \(error)")
            return
        }
    
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        
        /// `AVCaptureMetadataOutput` metadata object types.
        var metadata = [
            
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
                
                // Send the result back to JavaScript
                let jsCode = "receiveScanResult('\(stringValue)');"
                webView.evaluateJavaScript(jsCode, completionHandler: nil)
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


// web view 页面加载状态响应
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

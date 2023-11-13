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
    
    private let JS_CODE_SCAN: String = "scanCode"
    
    var webView: WKWebView!
    var refreshControl: UIRefreshControl!
    var vc: QQScanViewController!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the WKUserContentController to handle JavaScript messages
        let contentController = WKUserContentController()
        contentController.add(self, name: JS_CODE_SCAN)
        
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
        //view = webView
        // 允许左滑右滑，默认值为NO；设置为YES后，即可实现左右滑手势可用。
        webView.allowsBackForwardNavigationGestures = true
        view.addSubview(webView)
        
        // Initialize UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)
        
        var urlString: String = NsyyConfig.NSYY_URL
        if let selecter = UserDefaults.standard.value(forKey: NsyyConfig.NSYY_CONFIG_IDENTIFIER) as? String {
            switch selecter {
            case "nsyy":
                urlString = NsyyConfig.NSYY_URL
            case "nsyy-yf":
                urlString = NsyyConfig.NSYY_YF_URL
            default:
                urlString = NsyyConfig.NSYY_URL
            }
        }
        print("\(#function) 即将加载 \(urlString)")
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        webView.load(request)
        
        NsyyBluetooth.setWebView(webView: webView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 适当的时机 移除 WKScriptMessageHandler 防止引用循环
        webView.configuration.userContentController.removeScriptMessageHandler(forName: JS_CODE_SCAN)
    }
    
    @objc func refreshWebView() {
        // Reload the web page
        webView.reload()
    }
    
    // 全屏展示
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }

    // MARK: JS 调用 swift
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == JS_CODE_SCAN {
            print("\(#function) 执行 \(message.name)")
            codeScan()
        }
    }
    
    // MARK: - ---模仿qq扫码界面---------
    func codeScan() {
        print("\(#function) 准备开始扫码")

        vc = QQScanViewController()
        var style = LBXScanViewStyle()
        style.animationImage = UIImage(named: "qrcode_scan_light_green")
        vc.scanStyle = style
        vc.scanResultDelegate = self
        
        present(vc, animated: true, completion: nil)
    }
    
    
    func receiveScanReturn(code: String) {
        print("\(#function) 关闭扫码页面")
        vc.dismiss(animated: true, completion: nil)
        
        let jsCode = "receiveScanResult('\(code)');"
        print("\(#function) 调用 js 方法 \(jsCode)")
        
        let time = DispatchTime.now() + DispatchTimeInterval.milliseconds(800)
        DispatchQueue.main.asyncAfter(deadline: time){
            self.webView.evaluateJavaScript(jsCode, completionHandler: { (result, error) in
                if let error = error {
                    print("Error calling JavaScript function: \(error)")
                } else if let result = result {
                    print("JavaScript result: \(result)")
                }
            })
        }
    }
    

    
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
        
        refreshControl.endRefreshing()
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

// MARK: - 处理扫码结果
extension NsyyViewController: LBXScanViewControllerDelegate {
    func scanFinished(scanResult: LBXScanResult, error: String?) {
        print("\(#function) code scan result: \(scanResult)")
        self.receiveScanReturn(code: scanResult.strScanned!)
    }
}

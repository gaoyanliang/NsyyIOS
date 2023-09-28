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

// 注意： 要想正常加载指定 URL 需要在 info.plist 中配置 App Transport Security Settings - Allow Arbitrary Loads = true
class NsyyViewController: UIViewController {
    
    private let urlString: String = "http://oa.nsyy.com.cn:6060"
    var webView: WKWebView!

    var nsyyLocation: NsyyLocation = NsyyLocation()
    var bluetoothUtil: BluetoothUtil = BluetoothUtil()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 加载南石医院 OA 系统
        loadNsyyView()
        
        // 开启位置服务，并自动更新当前位置
        nsyyLocation.setUpLocation()
        
        // 开启蓝牙
        bluetoothUtil.openBluetoothAdapter(controller: self)
    }
    
    // 加载南石医院 oa 页面
    func loadNsyyView() {
        // Initialize WKWebView
        webView = WKWebView(frame: view.frame)
        
        // Implement WKNavigationDelegate if needed
        webView.navigationDelegate = self
        
        // 允许左滑右滑，默认值为NO；设置为YES后，即可实现左右滑手势可用。
        webView.allowsBackForwardNavigationGestures = true
        
        view.addSubview(webView)

        // Load a URL
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
}


// web view 页面加载状态响应
extension NsyyViewController: WKNavigationDelegate {
    
    // 页面开始加载时调用（开始请求服务器，并加载页面）
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!){
        print("=====> nsyy view didStart...... \(String(describing: webView.url))")
    }

    // 当内容开始返回时调用(开始渲染页面时调用，响应的内容到达主页面的时候响应,刚准备开始渲染页面)
    func webView(_ webview: WKWebView, didCommit navigation: WKNavigation!) {
        print("=====> nsyy view didCommit......")
    }

    // 页面加载完成之后调用
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // This method is called when the web view finishes loading a page.
        // You can perform actions after the page is fully loaded.
        print("=====> nsyy view didFinish. Page loaded successfully.")

    }

    // 页面加载失败时调用
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("=====> Failed to load: \(error.localizedDescription)")
    }
}

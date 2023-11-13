# 南石医院 IOS app

Nsyy App 需要提供的功能

1. app 中内嵌浏览器（访问固定内容，南石OA系统？）
2. 提供系统功能
   1. 获取当前位置
   2. 发送消息通知
   3. 支持连接蓝牙秤
   4. 支持扫码 （直接扫码 / 从相册扫码）
3. 要求 app 能够常驻后台，并实现自启动


## 熟悉 IOS 开发

IOS开发可以使用 Object- C 和 Swift，本次开发主要采用 Swift

通过下面文章中的案例可以简单了解 IOS 开发的工具使用，开发流程等。并且快速开发一个 IOS App Demo

[面向菜鸟的 iOS App 开发入门：强大而有趣的 Swift 编程](https://www.dusaiphoto.com/article/178/)

[Swift 编程语言中文教程](https://swift.bootcss.com/)

## 功能一： 内嵌浏览器，访问 OA 系统

IOS 同 Android 类似，也是通过 WebView 来加载指定网站，使用 WebView 可以实现功能一

下面是一个使用 web view 加载指定网站的 Demo

[IOS WebView Demo](https://www.youtube.com/watch?v=pLiT5DdjEbM)

参考文章：

- [https://github.com/federicoazzu/WebViewTutorial/blob/main/WebViewTutorial/ContentView.swift](https://github.com/federicoazzu/WebViewTutorial/blob/main/WebViewTutorial/ContentView.swift)
- [https://juejin.cn/post/6844903488414023688?from=search-suggest](https://juejin.cn/post/6844903488414023688?from=search-suggest)
- [https://juejin.cn/post/6844903966266884103#heading-16](https://juejin.cn/post/6844903966266884103#heading-16)
- [https://www.jianshu.com/p/7016be20f42f](https://www.jianshu.com/p/7016be20f42f)

当网站内容更新时，可以通过下拉操作来进行刷新，具体实现可参考：

```swift
import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

    var webView: WKWebView!
    var refreshControl: UIRefreshControl!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize WKWebView
        webView = WKWebView(frame: view.frame)
        webView.navigationDelegate = self
        view.addSubview(webView)

        // Initialize UIRefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshWebView), for: .valueChanged)
        webView.scrollView.addSubview(refreshControl)

        // Load an initial website
        if let url = URL(string: "https://example.com") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    @objc func refreshWebView() {
        // Reload the web page
        webView.reload()
    }

    // WKNavigationDelegate methods
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // This method is called when the web page has finished loading.
        // You can use it to update the UI or end the refreshing animation.
        refreshControl.endRefreshing()
    }
}
```

有关 web view 的所有实现均在 [NsyyViewController.swift](./NsyyIOS/NsyyViewController.swift) 中

## 功能二：提供系统功能

### 2.0 引入 Vapor 提供 web server 能力

这个需求需要提供的几种能力，需要 App 像 Web 应用一样提供接口供 OA 系统调用

要想实现预期的效果，需要在 App 中启动 web server 暴露指定端口才行，通过调研 [Vapor](https://vapor.codes/) 可以满足要求

当然还有其他第三方工具，也可以实现，但是都比较老，在 Github 上不太活跃，并没有采用。

在 IOS 项目中引入 Vapor:

```
# 1. 在 github 上 start vapor https://github.com/vapor/vaporhttps://github.com/vapor/vapor

# 2. 通过 xcode 打开 IOS 项目，在 File / Add Package Dependencies 中搜索并添加 Vapor 依赖，首次添加时，需要配置 GitHub 账号。
```

接入 Vapor 并不困难，观看文档即可

Vapor 相关的代码实现主要在： [vapor 目录](./NsyyIOS/vapor/)

主要用法：

```swift
# 1. 启动 vapor

let server = NsyyWebServer(port: 8081)
server.start()

# 2. 注册接口 

## 2.1 定义接口

    func routes(_ app: Application) throws {
        app.get("ping") { req async -> ReturnData in
            
            
            return ReturnData(isSuccess: true, code: 200, errorMsg: "nil", data: "SERVER OK")
        }
    }

## 2.2 注册接口

    func start() {
      Task(priority: .background) {
          do {
              try routes(app)
              try app.start()
          } catch {
              fatalError(error.localizedDescription)
          }
        }
    }
```

### 2.1 IOS 权限申请

IOS 中的权限申请，并不需要像 Android 一样进行统一管理，在 IOS 中即用即申请

注意需要在 info.plist 中添加对应权限的说明

例如：

```
Privacy - Location Usage Description - 请点击“允许”以允许访问
```


### 2.2 获取位置信息

在 IOS 中，获取位置信息的同时，也实现了自启动 & 常驻后台的功能。主要参考： 

- [ios开发应用如何自动重启 iphone应用自启动 ](https://blog.51cto.com/goody/6726438)
- [LocationAutomaticStartup](https://github.com/ticsmatic/LocationAutomaticStartup)

相关代码主要实现在： [location](./NsyyIOS/location/)

### 2.3 消息通知

IOS 消息通知功能实现比较统一，通过文档或者网上的 Demo 接入即可

功能实现参考：

- https://onevcat.com/2016/08/notification/#发送通知

相关代码主要实现在： [notification](./NsyyIOS/notification/)

### 2.4 使用蓝牙连接蓝牙秤

IOS 蓝牙功能实现比较统一，通过文档或者网上的 Demo 接入即可

参考文章：

- [https://www.bilibili.com/video/BV1Py4y1L7wa/?vd_source=0bac91cea85eca17b95f8cb541e419a5](https://www.bilibili.com/video/BV1Py4y1L7wa/?vd_source=0bac91cea85eca17b95f8cb541e419a5)
- [https://eciot.cn/#/bluetooth](https://eciot.cn/#/bluetooth)

该功能主要实现在 [buletooth](./NsyyIOS/bluetooth/)

需要注意的是：

IOS 隐私管理比较严格，在 Android 中可以通过蓝牙设备的 Mac 地址反向搜索 蓝牙设备，但是在 IOS 设备中获取不到 蓝牙设备的Mac 地址，只能通过 IOS 提供的方法主动去搜索蓝牙设备，搜索到之后在匹配对应的蓝牙设备。

要想拿到蓝牙设备的 mac 地址，需要蓝牙设备将 mac 地址广播出来，IOS 在搜索到 蓝牙设备时将 Mac 地址解析出来。 蓝牙秤的 Mac 地址是通过如下方式解析的。

```swift
extension NsyyBluetooth:CBCentralManagerDelegate {

    // 开始扫描之后会扫描到蓝牙设备，扫描到之后走到这个代理方法
    // MARK: 中心管理器扫描到了设备
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        guard let deviceName = peripheral.name, deviceName.count > 0 else {
            return
        }
        
        if let curBluetooth = NsyyBluetooth.bluetoothDeviceArray[peripheral.identifier.uuidString] {
            print("设备已存在 \(curBluetooth)")
            return
        }
        
        print("\(#function) 发现蓝牙设备 peripheral:\(peripheral) \n")
        var macAddress: String! = ""
        if let mData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            macAddress = mData.map { String(format: "%02X", $0) }.joined()
        }
        
        print("\(#function) 当前蓝牙设备 peripheral:\(peripheral) 的 mac 地址为 \(String(describing: macAddress))")
        NsyyBluetooth.bluetoothDeviceArray[peripheral.identifier.uuidString] = peripheral
        if macAddress != "" {
            NsyyBluetooth.bluetoothDeviceList[macAddress] = peripheral
        }
        
        // 如果发现配置的设备，直接尝试连接
        if let mac_address = UserDefaults.standard.value(forKey: "mac_address") as? String {
            for (add, device) in NsyyBluetooth.bluetoothDeviceList {
                if !add.contains(mac_address) {
                    continue
                }
                
                print("发现配置的蓝牙秤，开始尝试连接")
                
                if device.state == .connected || device.state == .connecting {
                    print("\(#function) 设备已连接. \(device) ")
                    break
                }
                
                print("\(#function) 设备未连接，开始连接 \(device) ")
                NsyyBluetooth.electronicWeigher = device
                doConnect(peripheral: NsyyBluetooth.electronicWeigher!)
            }
        } else {
            print("\(#function) 未发现蓝牙秤 MAC 地址相关配置")
        }
    }
}
```

在 IOS 应用中，通过 Settings.bundle 给应用添加 蓝牙秤 mac 地址的配置，安装 app 之后，在应用设置页面，进行配置。

相关代码主要实现在： [notification](./NsyyIOS/bluetooth/)


### 2.5 扫码

IOS 扫码功能，主要参考： https://github.com/MxABC/swiftScan

相关代码主要实现在： [notification](./NsyyIOS/code_scan/)

功能实现问题不大， 主要需要注意，适配设备横屏和竖屏

通过将扫码页面中的元素添加约束条件，来适配横屏和竖屏

```swift
func drawBottomItems() {
        if (bottomItemsView != nil) {
            return
        }
        // Create a new view
        bottomItemsView = UIView()
        //bottomItemsView!.backgroundColor = UIColor.red
        bottomItemsView!.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(bottomItemsView!)
        
        // 定位到 view 底部 中间
        NSLayoutConstraint.activate([
            // Set the view's width and height
            bottomItemsView!.widthAnchor.constraint(equalToConstant: view.frame.size.width * 2/3),
            bottomItemsView!.heightAnchor.constraint(equalToConstant: 150),

            // Center the view horizontally and vertically
            bottomItemsView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bottomItemsView!.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        
        btnFlash = UIButton()
        btnFlash!.translatesAutoresizingMaskIntoConstraints = false
        btnFlash!.setImage(UIImage(named: "qrcode_scan_btn_flash_nor"), for:UIControl.State.normal)
        btnFlash!.setImage(UIImage(named: "qrcode_scan_btn_flash_down"), for:UIControl.State.highlighted)
        btnFlash!.addTarget(self, action: #selector(openOrCloseFlash), for: UIControl.Event.touchUpInside)
        
        self.view.addSubview(btnFlash!)
        
        // 定位到 bottomItemsView 右侧
        NSLayoutConstraint.activate([
            // Set the view's width and height
            btnFlash!.widthAnchor.constraint(equalToConstant: 65),
            btnFlash!.heightAnchor.constraint(equalToConstant: 87),

            
            btnFlash!.rightAnchor.constraint(equalTo: bottomItemsView!.rightAnchor),
            btnFlash!.centerYAnchor.constraint(equalTo: bottomItemsView!.centerYAnchor)
        ])
        
        self.btnPhoto = UIButton()
        btnPhoto!.translatesAutoresizingMaskIntoConstraints = false
        btnPhoto!.setImage(UIImage(named: "qrcode_scan_btn_photo_nor"), for: UIControl.State.normal)
        btnPhoto!.setImage(UIImage(named: "qrcode_scan_btn_photo_down"), for: UIControl.State.highlighted)
        btnPhoto!.addTarget(self, action: #selector(openPhotoAlbum), for: UIControl.Event.touchUpInside)
    
        
        self.view.addSubview(btnPhoto!)
        
        // 定位到 bottomItemsView 左侧
        NSLayoutConstraint.activate([
            // Set the view's width and height
            btnPhoto!.widthAnchor.constraint(equalToConstant: 65),
            btnPhoto!.heightAnchor.constraint(equalToConstant: 87),

            
            btnPhoto!.leftAnchor.constraint(equalTo: bottomItemsView!.leftAnchor),
            btnPhoto!.centerYAnchor.constraint(equalTo: bottomItemsView!.centerYAnchor)
        ])
    }
```

NSLayoutConstraint 的更多用法可参考官方文档。

扫码功能不能通过 vapor 来提供，需要配合前端来使用。

通过调研，发现 web view 支持响应前端的 JS，并且 web view 也可以直接调用前端的 JS 方法，具体的使用方法如下：

前端需要提供如下 JS 方法：

```js
// 调用扫码功能 （前端主动调用）
// 主要方法名 ‘scanCode’ 需要和 app 中注册的 js 方法名保持一致
function scanCode() {
  window.webkit.messageHandlers.scanCode.postMessage('scanCode')
}

// 处理扫码返回值（由app调用，app 扫码完成之后，主动调用）
// 注意必须使用 window.method 的方式注册接受返回值方法，否则 app 找不到对应的方法
// 主要方法名 receiveScanResult 需要和 app 中调用的 js 方法名保持一致
window.receiveScanResult = function(data) {
    alert(data)
    message.value = data
    document.getElementById("data").value = data ;
    
    return 'scan code: ' + data;
}
```

app 中需要先注册对应的 js 方法

```swift
class NsyyViewController: UIViewController, WKScriptMessageHandler {

    private let JS_SCAN_CODE: String = "scanCode"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the WKUserContentController to handle JavaScript messages
        let contentController = WKUserContentController()
        contentController.add(self, name: JS_SCAN_CODE)
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = contentController
        
        webConfiguration.preferences = WKPreferences()
        webConfiguration.preferences.minimumFontSize = 0
        webConfiguration.preferences.javaScriptEnabled = true
        webConfiguration.processPool = WKProcessPool()
        webConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true

        // ....
        
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        webView.load(request)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 适当的时机 移除 WKScriptMessageHandler 防止引用循环
        webView.configuration.userContentController.removeScriptMessageHandler(forName: JS_SCAN_CODE)
    }
}
```

当扫码完成之后，app 通过如下方式直接调用前端 JS 方法

```swift
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
```


### 2.6 保存账户密码

根据设计，app 需要提供两个接口：

1. 查询用户信息
2. 存储用户信息

在进入app 时会先查询用户信息，如果有用户信息，直接返回给前端。 如果没有用户信息，直接返回null，在用户登陆成功之后，再将用户信息存储在app 中。

接口详情参考：接口 iOS 接口文档。

https://www.craft.me/s/rt04bEJyw9LH4s



### 2.7 连接扫码枪

扫码枪默认使用的是 HID 模式，这种模式，在日常使用过程中会出现偶尔断连的情况，导致数据上传失败。影响使用。

通过研究 & 讨论，决定改用 BLE 模式，这种模式需要由程序来控制扫码枪的连接，以及扫码数据的上报。

由于当前使用的扫码枪，并没有广播 mac address ，所以程序中解析不到扫码枪的 mac address ，但是通过和厂家沟通，扫码枪可以自定义 名称，所以可以通过修改扫码枪的名字来区别不同的扫码枪。

修改扫码枪蓝牙名称：

```
设置码（条形码）生成规则：%%BT=XxXxXxXx，XxXxXxXx 为需要设置的蓝牙名称，最长不超过20
个字符。例如 %%BT= BARCODE SCANNERE
```

在 setting bundle 中添加新配置 scan_gun 来配置扫码枪的名称。

同时提供新接口，来连接蓝牙秤（在断连或者数据上传失败时）

```
http://x.x.x.x:6079/conn_scan_gun
```




## APP 保活 & 自启动

参考 2.2 位置

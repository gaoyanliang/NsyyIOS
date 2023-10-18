//
//  QQScanViewController.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/16.
//


import UIKit

class QQScanViewController: LBXScanViewController {
    
    /**
    @brief  扫码区域上方提示文字
    */
    var topTitle: UILabel?

    /**
     @brief  闪关灯开启状态
     */
    var isOpenedFlash: Bool = false

// MARK: - 底部几个功能：开启闪光灯、相册

    //底部显示的功能项
    var bottomItemsView: UIView?

    //相册
    var btnPhoto: UIButton?

    //闪光灯
    var btnFlash: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //需要识别后的图像
        setNeedCodeImage(needCodeImg: true)
        
        // 根据设备调整扫描框位置 & 大小
        if UIDevice.current.userInterfaceIdiom == .pad {
            scanStyle!.xScanRetangleOffset = 160
        } else if UIDevice.current.userInterfaceIdiom == .phone {
            scanStyle!.xScanRetangleOffset = 30
        }
    
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawBottomItems()
    }
    

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
    
    //开关闪光灯
    @objc func openOrCloseFlash() {
        scanObj?.changeTorch()

        isOpenedFlash = !isOpenedFlash
        
        if isOpenedFlash {
            btnFlash!.setImage(UIImage(named: "qrcode_scan_btn_flash_down"), for:UIControl.State.normal)
        } else {
            btnFlash!.setImage(UIImage(named: "qrcode_scan_btn_flash_nor"), for:UIControl.State.normal)
        }
    }
    

}

//
//  HeaderVC.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/10/14.
//

import UIKit

public protocol HeaderViewControllerDelegate: class{
    
    func didClickedCloseButton()
    
}


public class HeaderVC: UIViewController {
    
    
    /// 设置present方式时的导航栏标题
    public override var title: String? {
        didSet{
            titleItem.title = title
        }
    }
    
    public lazy var closeImage = imageNamed("icon_back")
    
    @IBOutlet weak public var navigationBar: UINavigationBar!
    
    @IBOutlet weak var closeBtn: UIBarButtonItem!
    
    @IBOutlet weak var titleItem: UINavigationItem!
    
    public weak var delegate:HeaderViewControllerDelegate?
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        
        let bundle = Bundle(for: HeaderVC.self)
        
        super.init(nibName: nibNameOrNil, bundle: bundle)
        
        
        var statusHeight: CGFloat
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.windows.first(where: \.isKeyWindow)
            statusHeight = window?.windowScene?.statusBarManager?.statusBarFrame.height ?? 0
        } else {
            statusHeight = UIApplication.shared.statusBarFrame.height
        }
        
        
        view.frame = CGRect(x: 0, y: 0, width: screenWidth, height: statusHeight + navigationBar.frame.height)
        
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    public override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        setupUI()
        
    }
    
    @IBAction func closeBtnClick(_ sender: Any) {
        print("\(#function) 触发关闭")
        delegate?.didClickedCloseButton()
    }
    
    
}




// MARK: - CustomMethod
extension HeaderVC{
    
    func setupUI() {
        
        closeBtn.setBackButtonBackgroundImage(closeImage, for: .normal, barMetrics: .default)
        
    }
}


extension HeaderVC:UINavigationBarDelegate {
    
    public func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
}


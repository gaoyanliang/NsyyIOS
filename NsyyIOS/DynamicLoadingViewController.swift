//
//  DynamicLoadingViewController.swift
//  NsyyIOS
//
//  Created by yanliang gao on 2023/11/14.
//

import UIKit

class DynamicLoadingViewController: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        startLoadingAnimation()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        startLoadingAnimation()
    }

    private func setupView() {
        //backgroundColor = UIColor.blue
        backgroundColor = UIColor(hex: 0x333E5F)
        layer.cornerRadius = 100.0
    }

    private func startLoadingAnimation() {
        let scaleUpTransform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        let scaleDownTransform = CGAffineTransform.identity

        UIView.animate(withDuration: 0.5, delay: 0, options: [.autoreverse, .repeat], animations: {
            self.transform = scaleUpTransform
        }) { _ in
            UIView.animate(withDuration: 0.5) {
                self.transform = scaleDownTransform
            }
        }
    }

    func showInCenter() {
        if let window = UIApplication.shared.windows.first {
            center = window.center
            window.addSubview(self)
        }
    }
}


extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(hex & 0x0000FF) / 255.0,
            alpha: alpha
        )
    }
}

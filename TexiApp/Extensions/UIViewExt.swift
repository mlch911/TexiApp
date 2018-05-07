//
//  UIViewExt.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/3.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit

extension UIView {
    func fadeTo(alphaValue: CGFloat, withDuration duration: TimeInterval) {
        UIView.animate(withDuration: duration) {
            self.alpha = alphaValue
        }
    }
}


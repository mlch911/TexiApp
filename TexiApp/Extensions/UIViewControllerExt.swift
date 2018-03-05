//
//  UIViewControllerExt.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/24.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import UIKit

//extension UIViewController {
//    func shouldPresentLoadingView(_ stauts: Bool) {
//        var fadeView: UIView?
//        
//        if stauts {
//            fadeView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
//            fadeView?.backgroundColor = UIColor.white
//            fadeView?.alpha = 0.0
//            fadeView?.tag = 1005
//            
//            let spinner = UIActivityIndicatorView()
//            spinner.color = UIColor.darkGray
//            spinner.activityIndicatorViewStyle = .whiteLarge
//            spinner.center = view.center
//            
//            view.addSubview(fadeView!)
//            fadeView?.addSubview(spinner)
//            
//            spinner.startAnimating()
//            
//            fadeView?.fadeTo(alphaValue: 1.0, withDuration: 0.5)
//        } else {
//            for subview in view.subviews {
//                if subview.tag == 1005 {
//                    UIView.animate(withDuration: 0.5, animations: {
//                        subview.alpha = 0.0
//                    }, completion: { (finished) in
//                        subview.removeFromSuperview()
//                    })
//                }
//            }
//        }
//    }
//}


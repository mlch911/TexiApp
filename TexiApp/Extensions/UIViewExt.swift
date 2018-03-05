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
    
//    func bindToKeyboard() {
//        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
//        
//        let tapToDismissKeyboard = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard(sender:)))
//        self.addGestureRecognizer(tapToDismissKeyboard)
//    }
//    
//    @objc func keyboardWillChange(_ notification: Notification) {
//        let duration  = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
//        let targetFrame = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]as! NSValue).cgRectValue
//        
//        //        let curve = notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! UInt
//        //        let curFrame = (notification.userInfo![UIKeyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
//        //        let deltaY = targetFrame.origin.y - curFrame.origin.y
//        
//        //        UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: UIViewKeyframeAnimationOptions(rawValue: curve), animations: {
//        //            self.view.frame.origin.y += deltaY
//        //        }, completion: nil)
//        
//        /*键盘弹出视图上移*/
//        let deltaY = targetFrame.origin.y - UIScreen.main.bounds.height
//        
//        UIView.animate(withDuration: duration) {
//            self.transform = CGAffineTransform(translationX: 0, y: deltaY)
//        }
//    }
//    
//    @objc func dismissKeyboard(sender: UIGraphicsRenderer) {
//        self.endEditing(true)
//    }
}


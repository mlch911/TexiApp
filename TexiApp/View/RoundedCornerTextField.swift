//
//  RoundedCornerTextField.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/3.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit

class RoundedCornerTextField: UITextField {

    var textFieldOffset: CGFloat = 20.0
    
    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.height / 2
        self.clipsToBounds = true
        self.returnKeyType = .next
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0 + textFieldOffset, y: 0 + textFieldOffset / 2, width: self.frame.width - textFieldOffset, height: self.frame.height + textFieldOffset)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0 + textFieldOffset, y: 0 + textFieldOffset / 2, width: self.frame.width - textFieldOffset, height: self.frame.height + textFieldOffset)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return CGRect(x: 0 + textFieldOffset, y: 0 + textFieldOffset / 2, width: self.frame.width - textFieldOffset, height: self.frame.height - textFieldOffset)
    }
    
}

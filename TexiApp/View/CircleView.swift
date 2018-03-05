//
//  CircleView.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/2.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit

class CircleView: UIView {

    @IBInspectable var borderColor: UIColor? {
        didSet {
            setupCircle()
        }
    }
    
    override func awakeFromNib() {
        setupCircle()
    }
    
    func setupCircle() {
        self.layer.cornerRadius = self.frame.height / 2
        self.layer.borderWidth = 2.5
        self.layer.borderColor = borderColor?.cgColor
    }

}

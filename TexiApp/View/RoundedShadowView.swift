//
//  RoundedShadowView.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/2.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit

class RoundedShadowView: UIView {

    override func awakeFromNib() {
        setupShadow()
    }
    
    func setupShadow() {
        self.layer.cornerRadius = 10.0
        self.layer.shadowOpacity = 0.5
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 5.0
        self.layer.shadowOffset = CGSize(width: 0, height: 5)
    }

}

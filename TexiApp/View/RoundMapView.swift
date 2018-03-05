//
//  RoundMapView.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/27.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
import MapKit

class RoundMapView: MKMapView {

    override func awakeFromNib() {
        setupView()
    }
    
    func setupView() {
        self.layer.cornerRadius = self.frame.width / 2
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = 10.0
    }

}

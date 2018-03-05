//
//  CenterVCDelegate.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/2.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit

protocol CenterVCDelegate {
    func toggleLeftPanel()
    func addLeftPanelViewController()
    func animateLeftPanel(shouldExpand: Bool)
}

//
//  EnumModel.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/5/8.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation

enum AnnotationType {
    case driver
    case passenger
    case destination
}

//enum TripStep: String {
//    case accepted = "accepted"
//    case driverArrived = "driverArrived"
//    case inTravel = "inTravel"
//    case end = "end"
//}

enum SlideOutState {
    case collapsed
    case leftPanelExpanded
}

enum ShowWhichVC{
    case HomeVC
    case PaymentVC
}

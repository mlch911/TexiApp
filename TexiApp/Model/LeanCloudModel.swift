//
//  LeanCloudModel.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/5.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import LeanCloud

class Passenger: LCObject {
    @objc dynamic var id: LCString?
    @objc dynamic var email: LCString?
    
    override static func objectClassName() -> String {
        return "Passenger"
    }
}


class Driver: LCObject {
    @objc dynamic var id: LCString?
    @objc dynamic var email: LCString?
    @objc dynamic var isPickupModeEnable: LCBool?
    @objc dynamic var driverIsOnTrip: LCBool?
    
    override static func objectClassName() -> String {
        return "Driver"
    }
}

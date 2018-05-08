//
//  LeanCloudModel.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/5.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import LeanCloud

class User: LCUser {
    @objc dynamic var isDriver: LCBool!
    @objc dynamic var isPickupModeEnable: LCBool!
    @objc dynamic var isOnTrip: LCBool!
//    @objc dynamic var coordinate: [Double]?
//    @objc dynamic var tripCoordinate: [Double]?
}

class Trip: LCObject {
//    @objc dynamic var destinationCoordinate: [Double]!
//    @objc dynamic var pickupCoordinate: [Double]!
    @objc dynamic var passengerKey: LCString!
    @objc dynamic var driverKey: LCString?
    @objc dynamic var isTripAccepted: LCBool!
    @objc dynamic var step: LCString?
    @objc dynamic var addTime: LCDate!

    override static func objectClassName() -> String {
        return "Trip"
    }
}

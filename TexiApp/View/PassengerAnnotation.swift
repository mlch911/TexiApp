//
//  PassengerAnnotation.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/23.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import MapKit

class PassengerAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var key: String
    
    init(coordinate: CLLocationCoordinate2D, withKey key: String) {
        self.coordinate = coordinate
        self.key = key
    }
}

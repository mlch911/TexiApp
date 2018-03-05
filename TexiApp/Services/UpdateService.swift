//
//  UpdateService.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/10.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Firebase
import LeanCloud

class UpdateService {
    static var instance = UpdateService()
    
    func updatePassengerLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        if Auth.auth().currentUser != nil {
            FirebaseDataService.FRinstance.REF_PASSENGER.observeSingleEvent(of: .value, with: { (snapshot) in
                if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for user in userSnapshot {
                        if user.key == Auth.auth().currentUser?.uid {
                            FirebaseDataService.FRinstance.REF_PASSENGER.child(user.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            })
        }
        
        if let user = LCUser.current {
            user.set("coordinate", value: [coordinate.latitude, coordinate.longitude])
            user.save { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        if Auth.auth().currentUser != nil {
            FirebaseDataService.FRinstance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
                if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for user in userSnapshot {
                        if user.key == Auth.auth().currentUser?.uid {
                            if user.childSnapshot(forPath: "isPickupModeEnable").value as! Bool {
                                FirebaseDataService.FRinstance.REF_DRIVERS.child(user.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                            }
                        }
                    }
                }
            })
        }
        
        if let user = LCUser.current {
            user.set("coordinate", value: [coordinate.latitude, coordinate.longitude])
            user.save { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}

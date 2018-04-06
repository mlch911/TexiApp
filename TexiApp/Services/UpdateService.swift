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
    
    func observeTrips(handler: @escaping(_ coordinateDict: Dictionary<String, AnyObject>?) -> Void) {
        FirebaseDataService.FRinstance.REF_TRIPS.observe(.value) { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.hasChild("passengerKey") && trip.hasChild("tripIsAccepted") {
                        if let tripIsAccepted = trip.childSnapshot(forPath: "tripIsAccepted").value as? Bool {
                            guard tripIsAccepted else {
                                if let tripDict = trip.value as? Dictionary<String, AnyObject> {
                                    handler(tripDict)
                                }
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateTripWithCoordinatesUponRequest() {
        FirebaseDataService.FRinstance.REF_PASSENGER.observeSingleEvent(of: .value) { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        if !user.hasChild("isDriver") {
                            if let userDict = user.value as? Dictionary<String, AnyObject> {
                                let pickupArray = userDict["coordinate"] as! NSArray
                                let destinationArray = userDict["tripCoordinate"] as! NSArray
                                
                                FirebaseDataService.FRinstance.REF_TRIPS.child(user.key).updateChildValues(
                                    [
                                        "pickupCoordinate": [pickupArray[0], pickupArray[1]],
                                        "destinationCoordinate": [destinationArray[0], destinationArray[1]],
                                        "passengerKey": user.key,
                                        "tripIsAccepted": false
                                    ])
                            }
                        }
                    }
                }
            }
        }
    }
}

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
import NotificationBannerSwift

class UpdateService {
    static var instance = UpdateService()
    
    let drivers = FirebaseDataService.FRinstance.REF_DRIVERS
    let passengers = FirebaseDataService.FRinstance.REF_PASSENGERS
    let trips = FirebaseDataService.FRinstance.REF_TRIPS
    
    func updatePassengerLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        if Auth.auth().currentUser != nil {
            passengers.observeSingleEvent(of: .value, with: { (snapshot) in
                if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for user in userSnapshot {
                        if user.key == Auth.auth().currentUser?.uid {
                            self.passengers.child(user.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
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
            drivers.observeSingleEvent(of: .value, with: { (snapshot) in
                if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for driver in driverSnapshot {
                        if driver.key == Auth.auth().currentUser?.uid {
                            if driver.childSnapshot(forPath: "isPickupModeEnable").value as! Bool {
                                if driver.childSnapshot(forPath: "isOnTrip").value as! Bool {
                                    self.drivers.child(driver.key).updateChildValues(["coordinate": [coordinate.latitude, coordinate.longitude]])
                                }
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
        trips.observe(.childAdded) { (snapshot) in
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
    
    func updateTripForPassengerRequest() {
        passengers.observeSingleEvent(of: .value) { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == Auth.auth().currentUser?.uid {
                        if !user.hasChild("isDriver") {
                            if let userDict = user.value as? Dictionary<String, AnyObject> {
                                let pickupArray = userDict["coordinate"] as! NSArray
                                let destinationArray = userDict["tripCoordinate"] as! NSArray
                                
                                self.trips.child(user.key).updateChildValues(
                                    [
                                        "pickupCoordinate": [pickupArray[0], pickupArray[1]],
                                        "destinationCoordinate": [destinationArray[0], destinationArray[1]],
                                        "passengerKey": user.key,
                                        "tripIsAccepted": false
                                ]) { (error, reference) in
                                    if let error = error {
                                        self.errorPresent(withError: error)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func acceptTrip(withPassengerKey passengerkey: String, withDriverKey driverKey: String, handler: @escaping(_ finished: Bool) -> Void) {
        trips.child(passengerkey).observeSingleEvent(of: .value) { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.key == "tripIsAccepted" {
                        guard trip.value as! Bool else {
                            self.trips.child(passengerkey).updateChildValues(["driverKey": driverKey, "tripIsAccepted": true]) { (error, reference) in
                                if let error = error {
                                    self.errorPresent(withError: error)
                                }
                            }
                            self.drivers.child(driverKey).updateChildValues(["isOnTrip": true]) { (error, reference) in
                                if let error = error {
                                    self.errorPresent(withError: error)
                                }
                            }
                            UserDefaults.standard.set(true, forKey: "isOnTrip")
                            return
                        }
                    }
                }
            }
        }
        handler(true)
    }
    
    func cancelTrip(withPassengerKey passengerkey: String) {
        trips.child(passengerkey).removeValue { (error, reference) in
            if let error = error {
                self.errorPresent(withError: error)
            }
        }
        passengers.child(passengerkey).child("tripCoordinate").removeValue { (error, reference) in
            if let error = error {
                self.errorPresent(withError: error)
            }
        }
    }
    
    func cancelTrip(withPassengerKey passengerkey: String,withDriverKey driverKey: String) {
        trips.child(passengerkey).removeValue { (error, reference) in
            if let error = error {
                self.errorPresent(withError: error)
            }
        }
        passengers.child(passengerkey).child("tripCoordinate").removeValue { (error, reference) in
            if let error = error {
                self.errorPresent(withError: error)
            }
        }
        drivers.child(driverKey).child("isOnTrip").setValue(false) { (error, reference) in
            if let error = error {
                self.errorPresent(withError: error)
            }
        }
    }
    
    func finishTrip() {
        
    }
    
    //MARK:  /**********errorPresent**********/
    func errorPresent(withError error: Error) {
        let banner = NotificationBanner(title: "Error!", subtitle: error.localizedDescription, style: .danger)
        banner.show()
        print(error.localizedDescription)
    }
}

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
//import Firebase
import LeanCloud
import NotificationBannerSwift

class UpdateService {
    static var instance = UpdateService()
    var trips: [Trip]!
    
//    let drivers = FirebaseDataService.FRinstance.REF_DRIVERS
//    let passengers = FirebaseDataService.FRinstance.REF_PASSENGERS
//    let trips = FirebaseDataService.FRinstance.REF_TRIPS
//    let drivers = LCQuery(className: "_User")
//    let passengers = LCQuery(className: "_User")
//    let trips = LCQuery(className: "Trip")
    
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D) {
        if let user = LCUser.current {
            user.set("coordinate", value: [coordinate.latitude, coordinate.longitude])
            user.set("coordinateUpdateTime", value: LCDate.init())
            user.save { result in
                switch result {
                case .success:
                    break
                case .failure(let error):
                    self.errorPresent(withError: error)
                }
            }
        }
    }
    
    func observeTrips(handler: @escaping(_ trip: Trip) -> Void) {
//        trips.observe(.childAdded) { (snapshot) in
//            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                for trip in tripSnapshot {
//                    if trip.hasChild("passengerKey") && trip.hasChild("isTripAccepted") {
//                        if let isTripAccepted = trip.childSnapshot(forPath: "isTripAccepted").value as? Bool {
//                            guard isTripAccepted else {
//                                if let tripDict = trip.value as? Dictionary<String, AnyObject> {
//                                    handler(tripDict)
//                                }
//                                return
//                            }
//                        }
//                    }
//                }
//            }
//        }

//        let date = Date(timeIntervalSinceNow: -60)
        let query = LCQuery(className: "Trip")
        
//        query.whereKey("addTime", .greaterThanOrEqualTo(date))
        query.find { (result) in
            if result.isSuccess {
                self.trips = result.objects as! [Trip]
                if self.trips.count >= 0 {
                    for trip in self.trips {
                        if trip.isTripAccepted == false {
                            handler(trip)
                        }
                    }
                }
            } else {
                self.errorPresent(withError: result.error)
            }
        }
    }
    
    func updateTripForPassengerRequest() {
//        passengers.observeSingleEvent(of: .value) { (snapshot) in
//            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                for user in userSnapshot {
//                    if user.key == Auth.auth().currentUser?.uid {
//                        if !user.hasChild("isDriver") {
//                            if let userDict = user.value as? Dictionary<String, AnyObject> {
//                                let pickupArray = userDict["coordinate"] as! NSArray
//                                let destinationArray = userDict["tripCoordinate"] as! NSArray
//
//                                self.trips.child(user.key).updateChildValues(
//                                    [
//                                        "pickupCoordinate": [pickupArray[0], pickupArray[1]],
//                                        "destinationCoordinate": [destinationArray[0], destinationArray[1]],
//                                        "passengerKey": user.key,
//                                        "isTripAccepted": false
//                                ]) { (error, reference) in
//                                    if let error = error {
//                                        self.errorPresent(withError: error)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
        
        if UserDefaults.standard.value(forKey: "isDriver") as! Bool == false {
            let query = LCQuery(className: "_User")
            query.get((LCUser.current?.objectId)!) { (result) in
                if result.isSuccess {
                    if let passenger = result.object as? Driver {
                        let trip = Trip()
                        trip.addTime = LCDate()
//                        trip.pickupCoordinate = passenger.get("coordinate")?.rawValue as? [Double]
//                        trip.destinationCoordinate = passenger.get("tripCoordinate")?.rawValue as? [Double]
                        trip.passengerKey = LCUser.current?.objectId
                        trip.isTripAccepted = false
                        trip.set("pickupCoordinate", value: passenger.get("coordinate")?.rawValue as? [Double])
                        trip.set("destinationCoordinate", value: passenger.get("tripCoordinate")?.rawValue as? [Double])
                        trip.save({ (result) in
                            if result.isFailure {
                                self.errorPresent(withError: result.error)
                            }
                        })
                    }
                } else {
                    self.errorPresent(withError: result.error)
                }
            }
        }
    }
    
    func acceptTrip(withPassengerKey passengerKey: String, withDriverKey driverKey: String, handler: @escaping(_ finished: Bool) -> Void) {
//        trips.child(passengerKey).observeSingleEvent(of: .value) { (snapshot) in
//            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                for trip in tripSnapshot {
//                    if trip.key == "isTripAccepted" {
//                        guard trip.value as! Bool else {
//                            self.trips.child(passengerkey).updateChildValues(["driverKey": driverKey, "isTripAccepted": true]) { (error, reference) in
//                                if let error = error {
//                                    self.errorPresent(withError: error)
//                                }
//                            }
//                            self.drivers.child(driverKey).updateChildValues(["isOnTrip": true]) { (error, reference) in
//                                if let error = error {
//                                    self.errorPresent(withError: error)
//                                }
//                            }
//
//                            return
//                        }
//                    }
//                }
//            }
//        }
//        handler(true)
        
        let query = LCQuery(className: "Trip")
        query.whereKey("passengerKey", .equalTo(passengerKey))
        query.find { (result) in
            if result.isSuccess {
                let trip = result.objects?.first as! Trip
                if trip.isTripAccepted == false {
                    trip.driverKey = LCString(driverKey)
                    trip.isTripAccepted = true
                    trip.save({ (result) in
                        if result.isSuccess {
                            let query = LCQuery(className: "_User")
                            query.get(driverKey, completion: { (result) in
                                if result.isSuccess {
                                    let driver = result.object as! Driver
                                    driver.isOnTrip = true
                                    driver.save({ (result) in
                                        if result.isSuccess {
                                            UserDefaults.standard.set(true, forKey: "isOnTrip")
                                            handler(true)
                                        } else {
                                            self.errorPresent(withError: result.error)
                                            handler(false)
                                        }
                                    })
                                } else {
                                    self.errorPresent(withError: result.error)
                                    handler(false)
                                }
                            })
                        } else {
                            self.errorPresent(withError: result.error)
                            handler(false)
                        }
                    })
                } else {
                    handler(false)
                }
            } else {
                self.errorPresent(withError: result.error)
                handler(false)
            }
        }
    }
    
    func cancelTrip(isDriver: Bool) {
        let query = LCQuery(className: "Trip")
        query.whereKey("passengerKey", .equalTo((LCUser.current?.objectId)!))
        query.find { (result) in
            if result.isSuccess {
                if let trip = result.objects?.first as? Trip {
                    if trip.isTripAccepted.rawValue as? Bool == true {
                        let query = LCQuery(className: "_User")
                        query.get(trip.driverKey!) { (result) in
                            if result.isSuccess {
                                if let driver = result.object as? Driver {
                                    driver.isOnTrip = false
                                    driver.save({ (result) in
                                        if result.isFailure {
                                            self.errorPresent(withError: result.error)
                                        }
                                    })
                                }
                            } else {
                                self.errorPresent(withError: result.error)
                            }
                        }
                    }
                    LCUser.current?.set("isOnTrip", value: false)
                    LCUser.current?.save({ (result) in
                        if result.isFailure {
                            self.errorPresent(withError: result.error)
                        }
                    })
                    trip.delete({ (result) in
                        if result.isSuccess {
                            let banner = NotificationBanner(title: "Success", subtitle: "取消成功！", style: .success)
                            banner.show()
                        } else {
                            self.errorPresent(withError: result.error)
                        }
                    })
                }
            } else {
                self.errorPresent(withError: result.error)
            }
        }
        
//        query.get(passengerKey) { (result) in
//            if result.isSuccess {
//                let trip = result.object as! Trip
//                let query = LCQuery(className: "_User")
//                query.get(trip.passengerKey, completion: { (result) in
//                    if result.isSuccess {
//                        let passenger = result.object as! Driver
//                        passenger.set("tripCoordinate", value: nil)
//                        passenger.save({ (result) in
//                            if result.isSuccess {
//                                UserDefaults.standard.set(false, forKey: "isOnTrip")
//                            } else {
//                                self.errorPresent(withError: result.error)
//                            }
//                        })
//                    } else {
//                        self.errorPresent(withError: result.error)
//                    }
//                })
//                trip.delete({ (result) in
//                    if result.isFailure {
//                        self.errorPresent(withError: result.error)
//                    }
//                })
//            } else {
//                self.errorPresent(withError: result.error)
//            }
//        }
        
//        trips.child(passengerkey).removeValue { (error, reference) in
//            if let error = error {
//                self.errorPresent(withError: error)
//            }
//        }
//        passengers.child(passengerkey).child("tripCoordinate").removeValue { (error, reference) in
//            if let error = error {
//                self.errorPresent(withError: error)
//            }
//        }
    }
    
    func cancelTrip() {
        let query = LCQuery(className: "Trip")
        query.whereKey("driverKey", .equalTo((LCUser.current?.objectId)!))
        query.find { (result) in
            if result.isSuccess {
                if let trip = result.objects?.first as? Trip {
                    let query = LCQuery(className: "_User")
                    query.get(trip.passengerKey) { (result) in
                        if result.isSuccess {
                            if let passenger = result.object as? Driver {
                                passenger.isOnTrip = false
                                passenger.save({ (result) in
                                    if result.isFailure {
                                        self.errorPresent(withError: result.error)
                                    }
                                })
                            }
                        } else {
                            self.errorPresent(withError: result.error)
                        }
                    }
                    LCUser.current?.set("isOnTrip", value: false)
                    LCUser.current?.save({ (result) in
                        if result.isFailure {
                            self.errorPresent(withError: result.error)
                        }
                    })
                    trip.delete({ (result) in
                        if result.isSuccess {
                            let banner = NotificationBanner(title: "Success", subtitle: "取消成功！", style: .success)
                            banner.show()
                        } else {
                            self.errorPresent(withError: result.error)
                        }
                    })
                }
            } else {
                self.errorPresent(withError: result.error)
            }
        }
        
//        trips.child(passengerkey).removeValue { (error, reference) in
//            if let error = error {
//                self.errorPresent(withError: error)
//            }
//        }
//        passengers.child(passengerkey).child("tripCoordinate").removeValue { (error, reference) in
//            if let error = error {
//                self.errorPresent(withError: error)
//            }
//        }
//        drivers.child(driverKey).child("isOnTrip").setValue(false) { (error, reference) in
//            if let error = error {
//                self.errorPresent(withError: error)
//            }
//        }
    }
    
    func finishTrip() {
        
    }
    
    //MARK:  /**********errorPresent**********/
    func errorPresent(withError error: Error?) {
        var banner: NotificationBanner
        if error != nil {
            banner = NotificationBanner(title: "Error!", subtitle: error?.localizedDescription, style: .danger)
        } else {
            banner = NotificationBanner(title: "Error!", subtitle: "Unexpected Error!", style: .danger)
        }
        banner.show()
        print(error?.localizedDescription)
    }
}

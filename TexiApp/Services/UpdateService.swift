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
//        let date = Date(timeIntervalSinceNow: -5)
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
    
    func cancelTripForPassenger() {
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
    }
    
    func cancelTripForDriver() {
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

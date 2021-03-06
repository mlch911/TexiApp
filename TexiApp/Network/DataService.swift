//
//  DataService.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/4.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import LeanCloud
import NotificationBannerSwift

class DataService {
    static let instance = DataService()
    
    var trips: [Trip]!
    
    func isOnTrip(userKey: String, isDriver: Bool, handler: @escaping (_ status: Bool, _ driverKey: String?, _ passengerKey: String?, _ tripKey: String?) ->Void) {
        let query = LCQuery(className: "_User")
        query.get(userKey) { (result) in
            if result.isSuccess {
                if let isOnTrip = result.object?.value(forKey: "isOnTrip") as? Bool {
                    if isOnTrip {
                        let query = LCQuery(className: "Trip")
                        if isDriver {
                            query.whereKey("driverKey", .equalTo(userKey))
                            query.find({ (result) in
                                if result.isSuccess {
                                    let trip = result.objects?.first as! Trip
                                    handler(true, userKey, trip.passengerKey.stringValue, trip.objectId?.stringValue)
                                } else {
                                    self.errorPresent(withError: result.error)
                                }
                            })
                        } else {
                            query.whereKey("passengerKey", .equalTo(userKey))
                            query.find({ (result) in
                                if result.isSuccess {
                                    let trip = result.objects?.first as! Trip
                                    handler(true, trip.driverKey?.stringValue, userKey, trip.objectId?.stringValue)
                                } else {
                                    self.errorPresent(withError: result.error)
                                }
                            })
                        }
                    } else {
                        handler(false, nil, nil, nil)
                    }
                }
            } else {
                self.errorPresent(withError: result.error)
            }
        }
    }
    
    func checkUserStatus() {
        let hasUserData = UserDefaults.standard.value(forKey: "hasUserData") as? Bool
        let isDriver = UserDefaults.standard.value(forKey: "isDriver") as? Bool
        if hasUserData == true {
            if isDriver == true {
                let query = LCQuery(className: "_User")
                query.whereKey("isOnTrip", .selected)
                query.whereKey("isDriver", .selected)
                query.whereKey("isPickupModeEnable", .selected)
                query.get((LCUser.current?.objectId)!) { (result) in
                    if result.isSuccess {
                        if let driver = result.object as? User {
                            if let isOnTrip = driver.isOnTrip {
                                UserDefaults.standard.set(isOnTrip.rawValue, forKey: "isOnTrip")
                            }
                            if let isDriver = driver.isDriver {
                                UserDefaults.standard.set(isDriver.rawValue, forKey: "isDriver")
                            }
                            if let isPickupModeEnable = driver.isPickupModeEnable {
                                UserDefaults.standard.set(isPickupModeEnable.rawValue, forKey: "isPickupModeEnable")
                            }
                        }
                    } else {
                        self.errorPresent(withError: result.error)
                    }
                }
            } else {
                let query = LCQuery(className: "_User")
                query.get((LCUser.current?.objectId)!) { (result) in
                    if result.isSuccess {
                        if let driver = result.object as? User {
                            if let isOnTrip = driver.isOnTrip {
                                UserDefaults.standard.set(isOnTrip.rawValue, forKey: "isOnTrip")
                            }
                            if let isDriver = driver.isDriver {
                                UserDefaults.standard.set(isDriver.rawValue, forKey: "isDriver")
                            }
                        }
                    } else {
                        self.errorPresent(withError: result.error)
                    }
                }
            }
        }
    }
    
    func syncUserStatus() {
        if LCUser.current != nil {
            let query1 = LCQuery(className: "_User")
            query1.whereKey("objectID", .equalTo((LCUser.current?.objectId)!))
            query1.didChangeValue(forKey: "isPickupModeEnable")
            let query2 = LCQuery(className: "_User")
            query2.whereKey("objectID", .equalTo((LCUser.current?.objectId)!))
            query2.didChangeValue(forKey: "isOnTrip")
            let query = query1.or(query2)
            query.find { (result) in
                if result.isSuccess {
                    if let user = result.objects?.first as? User {
                        UserDefaults.standard.set(user.isPickupModeEnable.rawValue as? Bool, forKey: "isPickupModeEnable")
                        UserDefaults.standard.set(user.isOnTrip.rawValue as? Bool, forKey: "isOnTrip")
                    }
                } else {
                    self.errorPresent(withError: result.error)
                }
            }
        }
    }
    
    func loadDriverAnnotations(handler: @escaping (_ isSuccess: Bool, _ drivers: Dictionary<String , [Double]>?) -> Void ) {
        let query = LCQuery(className: "_User")
        query.whereKey("isDriver", .equalTo(true))
        query.whereKey("isPickupModeEnable", .equalTo(true))
        query.didChangeValue(forKey: "coordinateUpdateTime")
        query.whereKey("isOnTrip", .equalTo(false))
        query.whereKey("coordinate", .existed)
        query.whereKey("coordinate", .selected)
        query.find { (result) in
            if result.isSuccess {
                var drivers = Dictionary<String , [Double]>()
                for driver in result.objects! {
                    if let coordinate = driver.get("coordinate")?.rawValue as? [Double] {
                        if coordinate.count == 2 && coordinate[0] > -90 && coordinate[0] < 90 && coordinate[1] > -180 && coordinate[1] < 180 {
                            drivers[(driver.objectId?.stringValue)!] = coordinate
                        }
                    }
                }
                if drivers.count > 0 {
                    handler(true, drivers)
                } else {
                    handler(false, nil)
                }
            } else {
                self.errorPresent(withError: result.error)
                handler(false, nil)
            }
        }
    }
    
    func observeTrips(handler: @escaping(_ trip: Trip) -> Void) {
        let date = Date(timeIntervalSinceNow: -8)
        let query = LCQuery(className: "Trip")
        
        query.whereKey("addTime", .greaterThanOrEqualTo(date))
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
    
    func checkTripStep(handler: @escaping(_ isAccepted: Bool, _ driverKey: String?) -> Void) {
        let query = LCQuery(className: "Trip")
        query.whereKey("passengerKey", .equalTo((LCUser.current?.objectId)!))
        query.find { (result) in
            if result.isSuccess {
                if let trip = result.objects?.first as? Trip {
                    if trip.isTripAccepted?.rawValue as? Bool == true {
                        let tripStep = trip.step?.stringValue
                        let driverKey = trip.driverKey?.stringValue
                        UserDefaults.standard.set(tripStep, forKey: "tripStep")
                        handler(true, driverKey)
                    } else {
                        handler(false, nil)
                    }
                } else {
                    handler(false, nil)
                }
            } else {
                handler(false, nil)
                self.errorPresent(withError: result.error)
            }
        }
    }
    
    func checkTripStepForDriver(handler: @escaping(_ isSuccess: Bool, _ step: String?) -> Void) {
        let query = LCQuery(className: "Trip")
        query.whereKey("driverKey", .equalTo((LCUser.current?.objectId)!))
        query.find { (result) in
            if result.isSuccess {
                if let trip = result.objects?.first as? Trip {
                    if let step = trip.step?.rawValue as? String {
                        handler(true, step)
                    } else {
                        handler(false,nil)
                    }
                } else {
                    handler(false,nil)
                }
            } else {
                self.errorPresent(withError: result.error)
                handler(false,nil)
            }
        }
    }
    
    //MARK:  /**********errorPresent**********/
    func errorPresent(withError error: Error?) {
        if let error = error {
            let banner = NotificationBanner(title: "Error!", subtitle: error.localizedDescription, style: .danger)
            banner.show()
            print(error.localizedDescription)
        }
    }
}

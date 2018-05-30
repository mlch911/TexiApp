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
    
    func updateTripForPassengerRequest(handler: @escaping(_ isSuccess: Bool) -> Void) {
        if UserDefaults.standard.value(forKey: "isDriver") as! Bool == false {
            let trip = Trip()
            trip.addTime = LCDate()
            trip.passengerKey = LCUser.current?.objectId
            trip.isTripAccepted = false
            trip.set("pickupCoordinate", value: LCUser.current?.get("coordinate")?.rawValue as? [Double])
            trip.set("destinationCoordinate", value: LCUser.current?.get("tripCoordinate")?.rawValue as? [Double])
            trip.save({ (result) in
                if result.isSuccess {
                    LCUser.current?.set("isOnTrip", value: true)
                    LCUser.current?.save({ (result) in
                        if result.isSuccess {
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
                    trip.step = "accepted"
                    trip.save({ (result) in
                        if result.isSuccess {
                            LCUser.current?.set("isOnTrip", value: true)
                            LCUser.current?.save({ (result) in
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
                    let banner = NotificationBanner(title: "Sorry!", subtitle: "已经被别人抢先了！", style: .danger)
                    handler(false)
                    banner.show()
                }
            } else {
                self.errorPresent(withError: result.error)
                handler(false)
            }
        }
    }
    
    func updateTripStep(withTripStep tripStep: String, handler: @escaping(_ isSuccess: Bool) -> Void) {
        let query = LCQuery(className: "Trip")
        query.whereKey("driverKey", .equalTo((LCUser.current?.objectId)!))
        query.find { (result) in
            if result.isSuccess {
                if let trip = result.objects?.first as? Trip {
                    trip.step = LCString(tripStep)
                    trip.save({ (result) in
                        if result.isSuccess {
                            handler(true)
                        } else {
                            self.errorPresent(withError: result.error)
                            handler(false)
                        }
                    })
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
                if (result.objects?.count)! > 0 {
                    if let trip = result.objects?.first as? Trip {
                        if trip.isTripAccepted.rawValue as? Bool == true {
                            let query = LCQuery(className: "_User")
                            query.get(trip.driverKey!) { (result) in
                                if result.isSuccess {
                                    if let driver = result.object as? User {
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
                        trip.delete({ (result) in
                            if result.isSuccess {
                                let banner = NotificationBanner(title: "Success", subtitle: "取消成功！", style: .success)
                                banner.show()
                            } else {
                                self.errorPresent(withError: result.error)
                            }
                        })
                    }
                }
                LCUser.current?.set("isOnTrip", value: false)
                LCUser.current?.save({ (result) in
                    if result.isFailure {
                        self.errorPresent(withError: result.error)
                    }
                })
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
                    query.whereKey("objectId", .equalTo(trip.passengerKey))
                    query.find({ (result) in
                        if result.isSuccess {
                            if let passenger = result.objects?.first as? User {
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
                LCUser.current?.set("isOnTrip", value: false)
                LCUser.current?.save({ (result) in
                    if result.isFailure {
                        self.errorPresent(withError: result.error)
                    }
                })
            } else {
                self.errorPresent(withError: result.error)
            }
        }
    }
    
    func finishTrip(handler: @escaping(_ isSuccess: Bool) -> Void) {
        if UserDefaults.standard.value(forKey: "isDriver") as? Bool == false {
            let query = LCQuery(className: "Trip")
            query.whereKey("passengerKey", .equalTo((LCUser.current?.objectId)!))
            query.find { (result) in
                if result.isSuccess {
                    if let trip = result.objects?.first as? Trip {
                        let endTrip = LCObject(className: "EndTrip")
                        endTrip.set("passengerKey", value: trip.passengerKey)
                        endTrip.set("driverKey", value: trip.driverKey)
                        endTrip.set("addTime", value: trip.addTime)
                        endTrip.set("pickupCoordinate", value: trip.get("pickupCoordinate")?.rawValue)
                        endTrip.set("destinationCoordinate", value: trip.get("destinationCoordinate")?.rawValue)
                        endTrip.save({ (result) in
                            if result.isSuccess {
                                LCUser.current?.set("isOnTrip", value: false)
                                LCUser.current?.save({ (result) in
                                    if result.isFailure {
                                        self.errorPresent(withError: result.error)
                                    }
                                })
                                trip.delete({ (result) in
                                    if result.isSuccess {
                                        let banner = NotificationBanner(title: "Success", subtitle: "Travel Completed!", style: .success)
                                        banner.show()
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
                    }
                } else {
                    self.errorPresent(withError: result.error)
                    handler(false)
                }
            }
        } else {
            updateTripStep(withTripStep: "end") { (isSuccess) in
                if isSuccess {
                    LCUser.current?.set("isOnTrip", value: false)
                    LCUser.current?.save({ (result) in
                        if result.isSuccess {
                            let banner = NotificationBanner(title: "Success", subtitle: "Travel Completed!", style: .success)
                            banner.show()
                            handler(true)
                        } else {
                            self.errorPresent(withError: result.error)
                            handler(false)
                        }
                    })
                } else {
                    handler(false)
                }
            }
        }
    }
    
    //MARK:  /**********errorPresent**********/
    func errorPresent(withError error: Error?) {
        var banner: NotificationBanner
        if error != nil {
            banner = NotificationBanner(title: "Error!", subtitle: (error?.localizedDescription)!, style: .danger)
        } else {
            banner = NotificationBanner(title: "Error!", subtitle: "Unexpected Error!", style: .danger)
        }
        banner.show()
        print(error?.localizedDescription ?? "未知错误")
    }
}

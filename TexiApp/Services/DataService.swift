//
//  DataService.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/4.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
//import Firebase
import LeanCloud
import NotificationBannerSwift

//let DB_BASE = Database.database().reference()
class DataService {
    static let instance = DataService()

//    private var _REF_BASE = DB_BASE
//    private var _REF_PASSENGERS = DB_BASE.child("passenger")
//    private var _REF_DRIVERS = DB_BASE.child("driver")
//    private var _REF_TRIPS = DB_BASE.child("trip")

//    var REF_BASE: DatabaseReference {
//        return _REF_BASE
//    }
//    var REF_PASSENGERS: DatabaseReference {
//        return _REF_PASSENGERS
//    }
//    var REF_DRIVERS: DatabaseReference {
//        return _REF_DRIVERS
//    }
//    var REF_TRIPS: DatabaseReference {
//        return _REF_TRIPS
//    }

//    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>, isDriver: Bool) {
//        if isDriver {
//            DB_BASE.child("driver").child(uid).updateChildValues(userData, withCompletionBlock: { (error, reference) in
//                if let error = error {
//                    print(error.localizedDescription)
//                }
//            })
//        } else {
//            DB_BASE.child("passenger").child(uid).updateChildValues(userData, withCompletionBlock: { (error, reference) in
//                if let error = error {
//                    print(error.localizedDescription)
//                }
//            })
//        }
//    }
    
    func isOnTrip(userKey: String, isDriver: Bool, handler: @escaping (_ status: Bool, _ driverKey: String?, _ passengerKey: String?, _ tripKey: String?) ->Void) {
//        REF_DRIVERS.child(driverKey).observeSingleEvent(of: .value) { (snapshot) in
//            if let isOnTrip = snapshot.childSnapshot(forPath: "isOnTrip").value as? Bool {
//                if isOnTrip {
//                    self.REF_TRIPS.observeSingleEvent(of: .value, with: { (snapshot) in
//                        if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                            for trip in tripSnapshot {
//                                if trip.childSnapshot(forPath: "driverKey").value as? String == driverKey {
//                                    handler(true, driverKey, trip.key)
//                                }
//                            }
//                        }
//                    })
//                } else {
//                    handler(false, nil, nil)
//                }
//            }
//        }
        
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
                        if let driver = result.object as? Driver {
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
//                FirebaseDataService.FRinstance.REF_DRIVERS.child(Auth.auth().currentUser!.uid).observe(.value, with: { (snapshot) in
//                    if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                        for userProperty in userSnapshot {
//                            switch userProperty.key {
//                            case "isOnTrip":
//                                UserDefaults.standard.set(userProperty.value, forKey: "isOnTrip")
//                            case "isDriver":
//                                UserDefaults.standard.set(userProperty.value, forKey: "isDriver")
//                            case "isPickupModeEnable":
//                                UserDefaults.standard.set(userProperty.value, forKey: "isPickupModeEnable")
//                            default:
//                                break
//                            }
//                        }
//                    }
//                }, withCancel: { (error) in
//                    self.errorPresent(withError: error)
//                })
            } else {
                let query = LCQuery(className: "_User")
                query.get((LCUser.current?.objectId)!) { (result) in
                    if result.isSuccess {
                        if let driver = result.object as? Driver {
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
//                FirebaseDataService.FRinstance.REF_PASSENGERS.child(Auth.auth().currentUser!.uid).observe(.value, with: { (snapshot) in
//                    if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
//                        for userProperty in userSnapshot {
//                            switch userProperty.key {
//                            case "isOnTrip":
//                                UserDefaults.standard.set(userProperty.value, forKey: "isOnTrip")
//                            default:
//                                break
//                            }
//                        }
//                    }
//                }) { (error) in
//                    self.errorPresent(withError: error)
//                }
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
                    if let user = result.objects?.first as? Driver {
                        UserDefaults.standard.set(user.isPickupModeEnable.rawValue as? Bool, forKey: "isPickupModeEnable")
                        UserDefaults.standard.set(user.isOnTrip.rawValue as? Bool, forKey: "isOnTrip")
                    }
                } else {
                    self.errorPresent(withError: result.error)
                }
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

//
//  DataService.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/4.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import Foundation
import Firebase
import LeanCloud
import NotificationBannerSwift

let DB_BASE = Database.database().reference()
class FirebaseDataService {
    static let FRinstance = FirebaseDataService()

    private var _REF_BASE = DB_BASE
    private var _REF_PASSENGERS = DB_BASE.child("passenger")
    private var _REF_DRIVERS = DB_BASE.child("driver")
    private var _REF_TRIPS = DB_BASE.child("trip")

    var REF_BASE: DatabaseReference {
        return _REF_BASE
    }
    var REF_PASSENGERS: DatabaseReference {
        return _REF_PASSENGERS
    }
    var REF_DRIVERS: DatabaseReference {
        return _REF_DRIVERS
    }
    var REF_TRIPS: DatabaseReference {
        return _REF_TRIPS
    }

    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>, isDriver: Bool) {
        if isDriver {
            DB_BASE.child("driver").child(uid).updateChildValues(userData, withCompletionBlock: { (error, reference) in
                if let error = error {
                    print(error.localizedDescription)
                }
            })
        } else {
            DB_BASE.child("passenger").child(uid).updateChildValues(userData, withCompletionBlock: { (error, reference) in
                if let error = error {
                    print(error.localizedDescription)
                }
            })
        }
    }
    
    func driverIsOnTrip(driverKey: String, handler: @escaping (_ status: Bool?, _ driverKey: String?, _ tripKey: String?) ->Void) {
        REF_DRIVERS.child(driverKey).observeSingleEvent(of: .value) { (snapshot) in
            if let driverIsOnTrip = snapshot.childSnapshot(forPath: "driverIsOnTrip").value as? Bool {
                if driverIsOnTrip {
                    self.REF_TRIPS.observeSingleEvent(of: .value, with: { (snapshot) in
                        if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: "driverKey").value as? String == driverKey {
                                    handler(true, driverKey, trip.key)
                                }
                            }
                        }
                    })
                } else {
                    handler(false, nil, nil)
                }
            }
        }
    }
    
    func passengerIsOnTrip(passengerKey: String, handler: @escaping(_ status: Bool?, _ driverKey: String?, _ tripKey: String?) ->Void) {
        REF_TRIPS.observeSingleEvent(of: .value) { (tripSnapshot) in
            if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.key == passengerKey {
                        if trip.childSnapshot(forPath: "tripIsAccepted").value as! Bool {
                            let driverKey = trip.childSnapshot(forPath: "driverKey").value as? String
                            handler(true, driverKey, passengerKey)
                        } else {
                            handler(false, nil, nil)
                        }
                    } else {
                        handler(false, nil, nil)
                    }
                }
            }
        }
    }
    
    func checkUserStatus() {
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
            if UserDefaults.standard.value(forKey: "isDriver") as? Bool == true {
                FirebaseDataService.FRinstance.REF_DRIVERS.child(Auth.auth().currentUser!.uid).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                        for userProperty in userSnapshot {
                            switch userProperty.key {
                            case "driverIsOnTrip":
                                UserDefaults.standard.set(userProperty.value, forKey: "driverIsOnTrip")
                            case "isDriver":
                                UserDefaults.standard.set(userProperty.value, forKey: "isDriver")
                            case "isPickupModeEnable":
                                UserDefaults.standard.set(userProperty.value, forKey: "isPickupModeEnable")
                            default:
                                break
                            }
                        }
                    }
                }, withCancel: { (error) in
                    self.errorPresent(withError: error)
                })
            }
        }
    }
    
    //MARK:  /**********errorPresent**********/
    func errorPresent(withError error: Error) {
        let banner = NotificationBanner(title: "Error!", subtitle: error.localizedDescription, style: .danger)
        banner.show()
        print(error.localizedDescription)
    }
}


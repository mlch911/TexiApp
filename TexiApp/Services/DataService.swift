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

let DB_BASE = Database.database().reference()
class FirebaseDataService {
    static let FRinstance = FirebaseDataService()

    private var _REF_BASE = DB_BASE
    private var _REF_PASSENGERS = DB_BASE.child("passenger")
    private var _REF_DRIVERS = DB_BASE.child("driver")
    private var _REF_TRIPS = DB_BASE.child("trip")

    var REF_BASE :DatabaseReference {
        return _REF_BASE
    }
    var REF_PASSENGERS :DatabaseReference {
        return _REF_PASSENGERS
    }
    var REF_DRIVERS :DatabaseReference {
        return _REF_DRIVERS
    }
    var REF_TRIPS :DatabaseReference {
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
}


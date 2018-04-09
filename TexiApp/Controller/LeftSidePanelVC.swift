//
//  LeftSidePanelVC.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/2.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
import Firebase
import LeanCloud

class LeftSidePanelVC: UIViewController {
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var userTypeLabel: UILabel!
    @IBOutlet weak var userImageView: RoundImageView!
    @IBOutlet weak var loginBtn: UIButton!
    @IBOutlet weak var pickUpModeSwitch: UISwitch!
    @IBOutlet weak var pickUpModeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        pickUpModeSwitch.isOn = false
        pickUpModeSwitch.isHidden = true
        pickUpModeLabel.isHidden = true
        emailLabel.isHidden = true
        userTypeLabel.isHidden = true
        userImageView.isHidden = true
        loginBtn.setTitle("Sign Up / Login", for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
            observeLocalUser()
        } else {
            pickUpModeSwitch.isOn = false
            pickUpModeSwitch.isHidden = true
            pickUpModeLabel.isHidden = true
            emailLabel.isHidden = true
            userTypeLabel.isHidden = true
            userImageView.isHidden = true
            loginBtn.setTitle("Sign Up / Login", for: .normal)
        }
    }
    
    func observeLocalUser() {
        if UserDefaults.standard.value(forKey: "hasUserData") as! Bool {
            emailLabel.text = UserDefaults.standard.value(forKey: "name") as? String
            emailLabel.isHidden = false
            userTypeLabel.isHidden = false
            userImageView.isHidden = false
            if UserDefaults.standard.value(forKey: "isDriver") as! Bool {
                userTypeLabel.text = "Driver"
                pickUpModeSwitch.isHidden = false
                pickUpModeSwitch.isOn = UserDefaults.standard.value(forKey: "isPickupModeEnable") as! Bool
                pickUpModeLabel.isHidden = false
            } else {
                userTypeLabel.text = "Passenger"
                pickUpModeSwitch.isHidden = true
                pickUpModeLabel.isHidden = true
            }
            loginBtn.setTitle("Log Out", for: .normal)
        } else {
            observeFirebaseUser()
            observeLeanCloudUser()
        }
    }
    
    //MARK:  /**********LeanCloud**********/
    func observeLeanCloudUser() {
        if let user = LCUser.current {
            if user.get("isDriver")?.rawValue as? Bool == true {
                emailLabel.text = user.email?.stringValue
                userTypeLabel.text = "Driver"
                pickUpModeSwitch.isHidden = false
                pickUpModeSwitch.isOn = user.get("isPickUpModeEnable")?.rawValue as! Bool
                pickUpModeLabel.isHidden = false
                UserDefaults.standard.set(true, forKey: "hasUserData")
                if let isPickupModeEnable = user.get("isPickupModeEnable")?.rawValue as? Bool {
                    UserDefaults.standard.set(isPickupModeEnable, forKey: "isPickupModeEnable")
                }
                if let driverIsOnTrip = user.get("driverIsOnTrip")?.rawValue as? Bool {
                    UserDefaults.standard.set(driverIsOnTrip, forKey: "driverIsOnTrip")
                }
            } else {
                emailLabel.text = user.email?.stringValue
                userTypeLabel.text = "Passenger"
                pickUpModeSwitch.isHidden = true
                pickUpModeLabel.isHidden = true
                UserDefaults.standard.set(true, forKey: "hasUserData")
            }
            emailLabel.isHidden = false
            userTypeLabel.isHidden = false
            loginBtn.setTitle("Log Out", for: .normal)
            userImageView.isHidden = false
        } else {
            if let username = UserDefaults.standard.value(forKey: "name") as? String, let password = UserDefaults.standard.value(forKey: "password") as? String {
                LCUser.logIn(username: username, password: password) { result in
                    switch result {
                    case .success(let user):
                        if user.get("isDriver")?.rawValue as? Bool == true {
                            self.emailLabel.text = user.email?.stringValue
                            self.userTypeLabel.text = "Driver"
                            self.pickUpModeSwitch.isHidden = false
                            self.pickUpModeSwitch.isOn = user.get("isPickUpModeEnable")?.rawValue as! Bool
                            self.pickUpModeLabel.isHidden = false
                            UserDefaults.standard.set(true, forKey: "hasUserData")
                            if let isPickupModeEnable = user.get("isPickupModeEnable")?.rawValue as? Bool {
                                UserDefaults.standard.set(isPickupModeEnable, forKey: "isPickupModeEnable")
                            }
                            if let driverIsOnTrip = user.get("driverIsOnTrip")?.rawValue as? Bool {
                                UserDefaults.standard.set(driverIsOnTrip, forKey: "driverIsOnTrip")
                            }
                        } else {
                            self.emailLabel.text = user.email?.stringValue
                            self.userTypeLabel.text = "Passenger"
                            self.pickUpModeSwitch.isHidden = true
                            self.pickUpModeLabel.isHidden = true
                            UserDefaults.standard.set(true, forKey: "hasUserData")
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    //MARK:  /**********Firebase**********/
    func observeFirebaseUser() {
        if let user = Auth.auth().currentUser {
            FirebaseDataService.FRinstance.REF_PASSENGERS.observeSingleEvent(of: .value, with: { (snapshot) in
                if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for snap in snapshot {
                        if snap.key == user.uid {
                            self.emailLabel.text = user.email
                            self.userTypeLabel.text = "Passenger"
                            self.pickUpModeSwitch.isHidden = true
                            self.pickUpModeLabel.isHidden = true
                            UserDefaults.standard.set(true, forKey: "hasUserData")
                        }
                    }
                }
            })
            FirebaseDataService.FRinstance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
                if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for snap in snapshot {
                        if snap.key == user.uid {
                            self.emailLabel.text = user.email
                            self.userTypeLabel.text = "Driver"
                            self.pickUpModeSwitch.isHidden = false
                            self.pickUpModeSwitch.isOn = snap.childSnapshot(forPath: "isPickupModeEnable").value as! Bool
                            self.pickUpModeLabel.isHidden = false
                            UserDefaults.standard.set(true, forKey: "hasUserData")
                            if let isPickupModeEnable = FirebaseDataService.FRinstance.REF_DRIVERS.child(snap.key).value(forKey: "isPickupModeEnable") as? Bool {
                                UserDefaults.standard.set(isPickupModeEnable, forKey: "isPickupModeEnable")
                            }
                            if let driverIsOnTrip = FirebaseDataService.FRinstance.REF_DRIVERS.child(snap.key).value(forKey: "driverIsOnTrip") as? Bool {
                                UserDefaults.standard.set(driverIsOnTrip, forKey: "driverIsOnTrip")
                            }
                        }
                    }
                }
            })
            emailLabel.isHidden = false
            userTypeLabel.isHidden = false
            loginBtn.setTitle("Log Out", for: .normal)
            userImageView.isHidden = false
        } else {
            if let username = UserDefaults.standard.value(forKey: "name") as? String, let password = UserDefaults.standard.value(forKey: "password") as? String {
                Auth.auth().signIn(withEmail: username, password: password, completion: { (user, error) in
                    if error == nil {
                        if let user = user {
                            FirebaseDataService.FRinstance.REF_PASSENGERS.observeSingleEvent(of: .value, with: { (snapshot) in
                                if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                                    for snap in snapshot {
                                        if snap.key == user.uid {
                                            self.emailLabel.text = user.email
                                            self.userTypeLabel.text = "Passenger"
                                            self.pickUpModeSwitch.isHidden = true
                                            self.pickUpModeLabel.isHidden = true
                                            UserDefaults.standard.set(true, forKey: "hasUserData")
                                        }
                                    }
                                }
                            })
                            FirebaseDataService.FRinstance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
                                if let snapshot = snapshot.children.allObjects as? [DataSnapshot] {
                                    for snap in snapshot {
                                        if snap.key == user.uid {
                                            self.emailLabel.text = user.email
                                            self.userTypeLabel.text = "Driver"
                                            self.pickUpModeSwitch.isHidden = false
                                            self.pickUpModeSwitch.isOn = snap.childSnapshot(forPath: "isPickupModeEnable").value as! Bool
                                            self.pickUpModeLabel.isHidden = false
                                            UserDefaults.standard.set(true, forKey: "hasUserData")
                                            if let isPickupModeEnable = FirebaseDataService.FRinstance.REF_DRIVERS.child(snap.key).value(forKey: "isPickupModeEnable") as? Bool {
                                                UserDefaults.standard.set(isPickupModeEnable, forKey: "isPickupModeEnable")
                                            }
                                            if let driverIsOnTrip = FirebaseDataService.FRinstance.REF_DRIVERS.child(snap.key).value(forKey: "driverIsOnTrip") as? Bool {
                                                UserDefaults.standard.set(driverIsOnTrip, forKey: "driverIsOnTrip")
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                })
            }
        }
    }
    
    @IBAction func pickUpModeSwitchPressed(_ sender: Any) {
        if Auth.auth().currentUser != nil {
            FirebaseDataService.FRinstance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
                if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                    for user in userSnapshot {
                        if user.key == Auth.auth().currentUser?.uid {
                            FirebaseDataService.FRinstance.REF_DRIVERS.child(user.key).updateChildValues(["isPickupModeEnable": self.pickUpModeSwitch.isOn])
                            UserDefaults.standard.set(self.pickUpModeSwitch.isOn, forKey: "isPickupModeEnable")
                        }
                    }
                }
            })
        }
        
//        if let user = LCUser.current {
//            user.set("isPickupModeEnable", value: self.pickUpModeSwitch.isOn)
//            user.save { result in
//                switch result {
//                case .success:
//                    UserDefaults.standard.set(self.pickUpModeSwitch.isOn, forKey: "isPickupModeEnable")
//                case .failure(let error):
//                    print(error.localizedDescription)
//                }
//            }
//        }
        
        UserDefaults.standard.set(!(UserDefaults.standard.value(forKey: "isPickupModeEnable")as! Bool), forKey: "isPickupModeEnable")
        
    }
    
    @IBAction func loginBtnPressed(_ sender: Any) {
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
            do {
                try Auth.auth().signOut()
            } catch(let error) {
                print(error.localizedDescription)
            }
//            LCUser.logOut()
            pickUpModeSwitch.isOn = false
            pickUpModeSwitch.isHidden = true
            pickUpModeLabel.isHidden = true
            emailLabel.isHidden = true
            userTypeLabel.isHidden = true
            userImageView.isHidden = true
            loginBtn.setTitle("Sign Up / Login", for: .normal)
            UserDefaults.standard.set(false, forKey: "hasUserData")
            let homeVC = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "HomeVC") as? HomeVC
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                homeVC?.cancel()
            }
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
            let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginVC") as? LoginVC
            present(loginVC!, animated: true, completion: nil)
        }
    }
}

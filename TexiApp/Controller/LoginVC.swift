//
//  LoginVC.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/3.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
import Firebase
import LeanCloud

class LoginVC: UIViewController, UITextFieldDelegate {

    var isHidden = false
    
    @IBOutlet weak var emailField: RoundedCornerTextField!
    @IBOutlet weak var passwordField: RoundedCornerTextField!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var authBtn: RoundedShadowButton!
    
    @IBAction func authBtnPressed(_ sender: Any) {
//        authBtn.animateButton(shouldLoad: true, withMessage: nil)
        if emailField.text != nil && passwordField.text != nil {
            authBtn.animateButton(shouldLoad: true, withMessage: nil)
            self.view.endEditing(true)
            if let email = emailField.text, let password = passwordField.text {
                
                //MARK:  /**********LeanCloud**********/
//                let user = LCUser()
//                user.username = LCString(email)
//                user.email = LCString(email)
//                user.password = LCString(password)
//
//                LCUser.logIn(username: email, password: password, completion: { result in
//                    switch result {
//                    case .success(let result):
//                        LCUser.current = result
//                        if self.segmentControl.selectedSegmentIndex == 0 {
//                            let user = LCUser.current!
//                            user.set("isDriver", value: false)
//                            user.email = LCString(email)
//                            user.save { result in
//                                switch result {
//                                case .success:
//                                    print("LeanCloud上传数据成功")
//                                    UserDefaults.standard.set(false, forKey: "isDriver")
//                                    UserDefaults.standard.set(email, forKey: "name")
//                                    UserDefaults.standard.set(password, forKey: "password")
//                                case .failure(let error):
//                                    print("LeanCloud上传数据失败:\(error)")
//                                    self.authBtn.animateButton(shouldLoad: false, withMessage: "上传数据失败")
//                                }
//                            }
//                        } else {
//                            let user = LCUser.current!
//                            user.set("isDriver", value: true)
//                            user.email = LCString(email)
//                            user.set("driverIsOnTrip", value: false)
//                            user.set("isPickUpModeEnable", value: false)
//                            user.save { result in
//                                switch result {
//                                case .success:
////                                    user.objectId
//                                    print("LeanCloud上传数据成功")
//                                    UserDefaults.standard.set(true, forKey: "isDriver")
//                                    UserDefaults.standard.set(false, forKey: "isPickupModeEnable")
//                                    UserDefaults.standard.set(false, forKey: "driverIsOnTrip")
//                                    UserDefaults.standard.set(email, forKey: "name")
//                                    UserDefaults.standard.set(password, forKey: "password")
//                                case .failure(let error):
//                                    print("LeanCloud上传数据失败:\(error)")
//                                    self.authBtn.animateButton(shouldLoad: false, withMessage: "上传数据失败")
//                                }
//                            }
//                        }
//                        UserDefaults.standard.set(true, forKey: "hasUserData")
//                        print("LeanCloud登录成功")
//                        self.authBtn.animateButton(shouldLoad: false, withMessage: "登录成功")
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                            self.dismiss(animated: true, completion: nil)
//                        }
//                    case .failure:
//                        user.signUp({ result in
//                            switch result {
//                            case .success:
//                                LCUser.current = user
//                                if self.segmentControl.selectedSegmentIndex == 0 {
//                                    let user = LCUser.current!
//                                    user.set("isDriver", value: false)
//                                    user.email = LCString(email)
//                                    user.save { result in
//                                        switch result {
//                                        case .success:
//                                            print("LeanCloud上传数据成功")
//                                            UserDefaults.standard.set(false, forKey: "isDriver")
//                                            UserDefaults.standard.set(email, forKey: "name")
//                                            UserDefaults.standard.set(password, forKey: "password")
//                                        case .failure(let error):
//                                            print("LeanCloud上传数据失败:\(error)")
//                                            self.authBtn.animateButton(shouldLoad: false, withMessage: "上传数据失败")
//                                        }
//                                    }
//                                } else {
//                                    let user = LCUser.current!
//                                    user.set("isDriver", value: true)
//                                    user.email = LCString(email)
//                                    user.set("driverIsOnTrip", value: false)
//                                    user.set("isPickUpModeEnable", value: false)
//                                    user.save { result in
//                                        switch result {
//                                        case .success:
//                                            print("LeanCloud上传数据成功")
//                                            UserDefaults.standard.set(true, forKey: "isDriver")
//                                            UserDefaults.standard.set(false, forKey: "isPickupModeEnable")
//                                            UserDefaults.standard.set(false, forKey: "driverIsOnTrip")
//                                            UserDefaults.standard.set(email, forKey: "name")
//                                            UserDefaults.standard.set(password, forKey: "password")
//                                        case .failure(let error):
//                                            print("LeanCloud上传数据失败:\(error)")
//                                            self.authBtn.animateButton(shouldLoad: false, withMessage: "上传数据失败")
//                                        }
//                                    }
//                                }
//                                UserDefaults.standard.set(true, forKey: "hasUserData")
//                                print("LeanCloud注册成功")
//                                self.authBtn.animateButton(shouldLoad: false, withMessage: "注册成功")
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                    self.dismiss(animated: true, completion: nil)
//                                }
//                            case .failure(let error):
//                                switch error.code {
//                                case 125:
//                                    self.authBtn.animateButton(shouldLoad: false, withMessage: "电子邮箱地址无效")
//                                case 202:
//                                    self.authBtn.animateButton(shouldLoad: false, withMessage: "密码错误")
//                                case 203:
//                                    self.authBtn.animateButton(shouldLoad: false, withMessage: "密码错误")
//                                default:
//                                    self.authBtn.animateButton(shouldLoad: false, withMessage: "未知错误")
//                                    print(error.reason)
//                                }
//                                print("LeanCloud注册失败:\(error.reason ?? "未知错误")")
//                            }
//                        })
//                    }
//                })
                
                //MARK:  /**********Firebase**********/
                Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
                    if error == nil {
                        if let user = user {
                            if self.segmentControl.selectedSegmentIndex == 0 {
                                let userData = ["name": email] as [String: Any]
                                FirebaseDataService.FRinstance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                UserDefaults.standard.set(false, forKey: "isDriver")
                            } else {
                                let userData = ["name": email, "isDriver": true, "isPickupModeEnable": false, "driverIsOnTrip": false] as [String: Any]
                                FirebaseDataService.FRinstance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                UserDefaults.standard.set(true, forKey: "isDriver")
                                UserDefaults.standard.set(false, forKey: "isPickupModeEnable")
                                UserDefaults.standard.set(false, forKey: "driverIsOnTrip")
                            }
                        }
                        UserDefaults.standard.set(email, forKey: "name")
                        UserDefaults.standard.set(password, forKey: "password")
                        UserDefaults.standard.set(true, forKey: "hasUserData")
                        print("Firebase登录成功")
                        self.authBtn.animateButton(shouldLoad: false, withMessage: "登录成功")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    } else {
                        print("Firebase登录失败:\(error?.localizedDescription ?? "未知错误")")
                        Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                            if error != nil {
                                if let errorCode = AuthErrorCode(rawValue: error!._code) {
                                    switch errorCode {
                                    case .invalidEmail:
                                        print("Firebase注册失败:\(error?.localizedDescription ?? "未知错误")")
                                        self.authBtn.animateButton(shouldLoad: false, withMessage: "电子邮箱地址无效")
                                    case .emailAlreadyInUse:
                                        print("Firebase注册失败:\(error?.localizedDescription ?? "未知错误")")
                                        self.authBtn.animateButton(shouldLoad: false, withMessage: "密码错误")
                                    case .wrongPassword:
                                        print("Firebase注册失败:\(error?.localizedDescription ?? "未知错误")")
                                        self.authBtn.animateButton(shouldLoad: false, withMessage: "密码错误")
                                    case .weakPassword:
                                        print("Firebase注册失败:\(error?.localizedDescription ?? "未知错误")")
                                        self.authBtn.animateButton(shouldLoad: false, withMessage: "弱密码")
                                    default:
                                        print("Firebase注册失败:\(error?.localizedDescription ?? "未知错误")")
                                        self.authBtn.animateButton(shouldLoad: false, withMessage: "未知错误")
                                    }
                                }
                            } else {
                                if let user = user {
                                    if self.segmentControl.selectedSegmentIndex == 0 {
                                        let userData = ["name": email] as [String: Any]
                                        FirebaseDataService.FRinstance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: false)
                                        UserDefaults.standard.set(false, forKey: "isDriver")
                                    } else {
                                        let userData = ["name": email, "isDriver": true, "isPickupModeEnable": false, "driverIsOnTrip": false] as [String: Any]
                                        FirebaseDataService.FRinstance.createFirebaseDBUser(uid: user.uid, userData: userData, isDriver: true)
                                        UserDefaults.standard.set(true, forKey: "isDriver")
                                        UserDefaults.standard.set(false, forKey: "isPickupModeEnable")
                                        UserDefaults.standard.set(false, forKey: "driverIsOnTrip")
                                    }
                                }
                                UserDefaults.standard.set(email, forKey: "name")
                                UserDefaults.standard.set(password, forKey: "password")
                                UserDefaults.standard.set(true, forKey: "hasUserData")
                                print("Firebase注册成功")
                                self.authBtn.animateButton(shouldLoad: false, withMessage: "注册成功")
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.dismiss(animated: true, completion: nil)
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        view.bindToKeyboard()
        NotificationCenter.default.addObserver(self, selector: #selector(hideStatusBar), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showStatusBar), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        emailField.delegate = self
        passwordField.delegate = self
        emailField.returnKeyType = .next
        passwordField.returnKeyType = .join
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }
    
    override var prefersStatusBarHidden: Bool {
        return isHidden
    }
    
    @objc func showStatusBar(){
        isHidden = false
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    @objc func hideStatusBar(){
        isHidden = true
        UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 1003 {
            passwordField.becomeFirstResponder()
            return false
        } else {
            textField.resignFirstResponder()
            self.authBtn.animateButton(shouldLoad: true, withMessage: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.authBtnPressed(self)
            }
            return true
        }
    }
}

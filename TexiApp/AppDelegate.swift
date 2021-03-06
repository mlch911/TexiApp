//
//  AppDelegate.swift
//  TexiApp
//
//  Created by 闵罗琛 on 2018/2/1.
//  Copyright © 2018年 mlch911. All rights reserved.
//

import UIKit
//import Firebase
import LeanCloud
import IQKeyboardManagerSwift
import NotificationBannerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    fileprivate var containerVC = ContainerVC()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
//        FirebaseApp.configure()
        LeanCloud.initialize(applicationID: "XPpQiSHNcvLCzCbnzptdnGvI-gzGzoHsz", applicationKey: "8xb9rijslYcwWisswTwJ0J1j")
        
//        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.shared.enable = true
        
        window?.rootViewController = containerVC
        window?.makeKeyAndVisible()
        
        if UserDefaults.standard.value(forKey: "hasUserData") as? Bool == true {
            LCUser.logIn(username: UserDefaults.standard.value(forKey: "name") as! String, password: UserDefaults.standard.value(forKey: "password") as! String) { (result) in
                if result.isSuccess {
                    LCUser.current = result.object
                    DataService.instance.checkUserStatus()
                } else {
                    print(result.error.debugDescription)
                    UserDefaults.standard.set(false, forKey: "hasUserData")
                    LCUser.logOut()
                    let banner = NotificationBanner(title: "Error!", subtitle: "网络错误，请重新登录。", style: .danger)
                    banner.show()
                }
            }
        }
//        DataService.instance.checkUserStatus()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}


//
//  AppDelegate.swift
//  Chefbook
//
//  Created by Clint Shank on 7/26/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?


    func application(_ application: UIApplication,
                       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? )  -> Bool
    {
        ZLog.setupLogging()
        
        return true
    }
    
    
    func applicationWillResignActive(_ application: UIApplication )
    {
    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication )
    {
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication )
    {
    }
    
    
    func applicationDidBecomeActive(_ application: UIApplication )
    {
    }
    
    
    func applicationWillTerminate(_ application: UIApplication )
    {
    }
    
    

}


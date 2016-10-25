//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-22.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

   var window: UIWindow?

   // instantiate the CoreDataStack
   lazy var coreDataStack = CoreDataStack(modelName: "Virtual Tourist")
   
   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

      guard let navController = window?.rootViewController as? UINavigationController, let viewController = navController.topViewController as? MapViewController else { return true }
      
      // pass the Core Data context to the first viewController
      viewController.managedContext = coreDataStack.managedContext
      
      return true
   }

   func applicationDidEnterBackground(_ application: UIApplication) {
      coreDataStack.saveContext()
   }

   func applicationWillTerminate(_ application: UIApplication) {
      coreDataStack.saveContext()
   }


}


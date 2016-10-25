//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-22.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
   
   private let modelName: String
   
   init(modelName: String) {
      self.modelName = modelName
   }
   
   private lazy var storeContainer: NSPersistentContainer = {
      
      let container = NSPersistentContainer(name: self.modelName)
      container.loadPersistentStores { (storeDescription, error) in
         
         if let error = error as NSError? {
            print("Unresolved error loading persistent store: \(error), \(error.userInfo)")
         }
      }
      return container
   }()
   
   lazy var managedContext: NSManagedObjectContext = {
      return self.storeContainer.viewContext
   }()
   
   func saveContext() {
      
      guard managedContext.hasChanges else { return }
      
      do {
         try managedContext.save()
      } catch let error as NSError {
         print("Could not save context: \(error), \(error.userInfo)")
      }
      
   }
}

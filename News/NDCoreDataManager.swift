//
//  NDCoreDataManager.swift
//  News
//
//  Created by Sachin Vas on 7/14/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import CoreData

class NDCoreDataManager: NSObject {
    
    class var sharedManager: NDCoreDataManager {
        struct Singleton {
            static let instance = NDCoreDataManager()
        }
        return Singleton.instance
    }
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("News", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let documentDirectoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0]
        let url = documentDirectoryURL.URLByAppendingPathComponent("News.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch let error as NSError {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "com.datalicious.news", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        } catch {
            
        }
        
        return coordinator
    }()
    
    lazy var rootMOC: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    lazy var mainQueueMOC: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.parentContext = self.rootMOC
        return managedObjectContext
    }()
    
    lazy var backgroundMOC: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        managedObjectContext.parentContext = self.mainQueueMOC
        return managedObjectContext
    }()
}
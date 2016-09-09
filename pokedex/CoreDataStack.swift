//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by IT on 8/12/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import CoreData

class CoreDataStack {
    
    // MARK:  - Properties
    private let model : NSManagedObjectModel
    private let coordinator : NSPersistentStoreCoordinator
    private let modelURL : NSURL
    private let dbURL : NSURL
    let mainContext : NSManagedObjectContext
    let backgroundContext : NSManagedObjectContext

    // MARK:  - Initializers
    init?(modelName: String){
        
        // Assumes the model is in the main bundle
        guard let modelURL = NSBundle.mainBundle().URLForResource(modelName, withExtension: "momd") else {
            print("Unable to find \(modelName)in the main bundle")
            return nil}
        
        self.modelURL = modelURL
        
        // Try to create the model from the URL
        guard let model = NSManagedObjectModel(contentsOfURL: modelURL) else{
            print("unable to create a model from \(modelURL)")
            return nil
        }
        self.model = model
        
        
        
        // Create the store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        // create a context and add connect it to the coordinator
        mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        mainContext.persistentStoreCoordinator = coordinator
        mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        backgroundContext.persistentStoreCoordinator = coordinator
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Add a SQLite store located in the documents folder
        let fm = NSFileManager.defaultManager()
        
        guard let  docUrl = fm.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first else{
            print("Unable to reach the documents folder")
            return nil
        }
        
        self.dbURL = docUrl.URLByAppendingPathComponent("model.sqlite")


        let options = [NSMigratePersistentStoresAutomaticallyOption: true,
                       NSInferMappingModelAutomaticallyOption: true]

        do{
            try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: options)
            
        }catch{
            print("unable to add store at \(dbURL)")
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: mainContext)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(contextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: backgroundContext)
    }
    
    // MARK:  - Utils
    func addStoreCoordinator(storeType: String,
                             configuration: String?,
                             storeURL: NSURL,
                             options : [NSObject : AnyObject]?) throws{
        
        try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: dbURL, options: options)
        
    }

    @objc func contextDidSave(notification: NSNotification) {
        if let sender = notification.object as? NSManagedObjectContext {
            if sender == self.mainContext {
                self.backgroundContext.performBlock({ 
                    self.backgroundContext.mergeChangesFromContextDidSaveNotification(notification)
                })
            } else if sender == self.backgroundContext {
                self.mainContext.performBlock({ 
                    self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
                })
            }
        }
    }
}


// MARK:  - Removing data
extension CoreDataStack  {
    
    func dropAllData() throws{
        // delete all the objects in the db. This won't delete the files, it will
        // just leave empty tables.
        try coordinator.destroyPersistentStoreAtURL(dbURL, withType:NSSQLiteStoreType , options: nil)
        
        try addStoreCoordinator(NSSQLiteStoreType, configuration: nil, storeURL: dbURL, options: nil)

        
    }
}

// MARK:  - Save
extension CoreDataStack {
    
    func saveMainContext() {
        mainContext.performBlock { 
            do {
                if self.mainContext.hasChanges {
                    try self.mainContext.save()
                }
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }

    func saveBackgroundContext() {
        backgroundContext.performBlock {
            do {
                if self.backgroundContext.hasChanges {
                    try self.backgroundContext.save()
                }
            }
            catch let error as NSError {
                print(error.localizedDescription)
            }
        }
    }
}
















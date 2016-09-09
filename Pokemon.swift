//
//  Pokemon.swift
//  Pokedex
//
//  Created by IT on 9/1/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import CoreData
import UIKit

class Pokemon: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    convenience init(id: UInt, name: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entityForName(Pokemon.entityName(), inManagedObjectContext: context) {
            self.init(entity: ent, insertIntoManagedObjectContext: context)
            self.id = NSNumber(unsignedInteger: id)
            self.name = name
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
    
    class func entityName() -> String {
        return "Pokemon"
    }
}

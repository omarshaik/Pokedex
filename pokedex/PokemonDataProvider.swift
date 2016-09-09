//
//  PokemonDataProvider.swift
//  Pokedex
//
//  Created by IT on 9/2/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import UIKit
import CoreData

class PokemonDataProvider: NSObject {
    static private let stack = (UIApplication.sharedApplication().delegate as! AppDelegate).stack
    
    class func fetchPokemon() -> [Pokemon] {
        let fetchRequest = NSFetchRequest(entityName: Pokemon.entityName())
        let idSortDescriptor = NSSortDescriptor(key: PokeAPI.PokeResponseKeys.ID, ascending: true)
        fetchRequest.sortDescriptors = [idSortDescriptor]
        
        do {
            if let pokemonArray = try stack.mainContext.executeFetchRequest(fetchRequest) as? [Pokemon] {
                return pokemonArray
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return []
    }
    
    class func fetchPokemonForID(id: UInt) -> Pokemon? {
        let fetchRequest = NSFetchRequest(entityName: Pokemon.entityName())
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)
        
        do {
            if let pokemonArray = try stack.mainContext.executeFetchRequest(fetchRequest) as? [Pokemon] {
                return pokemonArray.first
            }
        } catch {
            
        }
        
        return nil
    }

    class func fetchPokemonInBackgroundForID(id: UInt) -> Pokemon? {
        let fetchRequest = NSFetchRequest(entityName: Pokemon.entityName())
        fetchRequest.predicate = NSPredicate(format: "id == %d", id)

        do {
            if let pokemonArray = try stack.backgroundContext.executeFetchRequest(fetchRequest) as? [Pokemon] {
                return pokemonArray.first
            }
        } catch {

        }

        return nil
    }
    
    class func saveMainContext() {
        stack.saveMainContext()
    }

    class func saveBackgroundContext() {
        stack.saveBackgroundContext()
    }
}

//
//  PokeAPI.swift
//  pokedex
//
//  Created by IT on 8/29/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import UIKit
import CoreData

typealias CompletionBlock = (allDownloadsCompleted: Bool, error: NSError?) -> Void

struct PokeAPI {
    
    static let session = NSURLSession.sharedSession()
    static let baseURL = pokemonURLFromParameters(nil)
    
    static func fetchNext15Pokemon() {
        session.getAllTasksWithCompletionHandler({ tasks in
            if tasks.count > 0 {
                return
            }
        })
        
        // all existing Pokemon in DB
        let pokemonArray = PokemonDataProvider.fetchPokemon()
        
        var startID: UInt
        if let lastIdDownloaded = pokemonArray.last?.id {
            startID = lastIdDownloaded.unsignedIntegerValue
        } else {
            startID = 0
        }
        
        let note = NSNotification(name: "PokemonDidFinishDownloading", object: nil)
        
        if startID < 151 {
            let window = (UIApplication.sharedApplication().delegate as? AppDelegate)?.window
            if let rootVC = window?.rootViewController {
                for view in rootVC.view.subviews {
                    if view is UIActivityIndicatorView {
                        view.removeFromSuperview()
                    }
                }
            }
            let spinner = window?.rootViewController?.showSpinner()
            PokeAPI.requestPokemon(startID, num: 15, completion: { (allDownloadsCompleted, error) in
                NSNotificationCenter.defaultCenter().postNotification(note)
                if let rootVC = window?.rootViewController {
                    for view in rootVC.view.subviews {
                        if view is UIActivityIndicatorView {
                            view.removeFromSuperview()
                        }
                    }
                }
                spinner?.hide()
            })
        } else {
            NSNotificationCenter.defaultCenter().postNotification(note)
        }
    }
    
    static func requestPokemon(startID: UInt, num: UInt, completion: CompletionBlock?) {
        var endID = startID + num
        endID = min(151, endID)
        for i in startID...endID {
            PokeAPI.requestPokemonForID(i, completion: { (allDownloadsCompleted, error) in
                if let completion = completion {
                    completion(allDownloadsCompleted: allDownloadsCompleted, error: error)
                }
            })
        }
    }
    
    static func requestPokemonForID(id: UInt, completion: CompletionBlock?) {
        if let _ = PokemonDataProvider.fetchPokemonForID(id) {
            return
        }
        
        session.getAllTasksWithCompletionHandler { tasks in
            for task in tasks {
                if task.taskDescription == "\(id)" {
                    return
                }
            }
        }
        
        let url = NSURL(string: "pokemon/\(id)", relativeToURL: baseURL)
        let request = NSURLRequest(URL: url!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                if error.code == NSURLErrorNotConnectedToInternet {
                    let note = NSNotification(name: "PokemonDownloadError", object: nil)
                    NSNotificationCenter.defaultCenter().postNotification(note)
                }
                
                if let completion = completion {
                    completion(allDownloadsCompleted: false, error: error)
                }
                return
            }
            
            guard let urlResponse = response as? NSHTTPURLResponse where (urlResponse.statusCode > 200 || urlResponse.statusCode < 300) else {
                return
            }
            
            if let data = data {
                if let jsonDict = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments) {
                    guard let name = jsonDict["name"] as? String else {
                        return
                    }

                    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).stack.backgroundContext

                    context.performBlock({
                        var pokemon: Pokemon
                        if let pokemonInDB = PokemonDataProvider.fetchPokemonInBackgroundForID(id) {
                            pokemon = pokemonInDB
                        } else {
                            pokemon = Pokemon(id: id, name: name.capitalizedString, context: context)
                        }

                        if let spritesDict = jsonDict["sprites"] as? [String:AnyObject] {
                            if let imageURLString = spritesDict["front_default"] as? String {
                                pokemon.urlString = imageURLString
                            }
                        }

                        if let typeDictArray = jsonDict["types"] as? [[String:AnyObject]] {
                            for typeDict in typeDictArray {
                                if let typeDictionary = typeDict["type"] as? [String:String] {
                                    if let typeName = typeDictionary["name"] {
                                        if !pokemon.types.contains(typeName) {
                                            pokemon.types.append(typeName)
                                        }
                                    }
                                }
                            }
                        }

                        PokemonDataProvider.saveBackgroundContext()
                    })

                    session.getAllTasksWithCompletionHandler({ tasks in
                        if tasks.count == 0 {
                            if let completion = completion {
                                completion(allDownloadsCompleted: true, error: nil)
                            }
                        }
                    })
                }
            }
        }

        task.taskDescription = "\(id)"
        
        task.resume()
    }
    
    
    static func requestPokemonDescriptionForID(id: UInt) {
    
        let url = NSURL(string: "characteristic/\(id)", relativeToURL: baseURL)
        let task = session.dataTaskWithURL(url!) { (data, response, error) in
            guard let urlResponse = response as? NSHTTPURLResponse where (urlResponse.statusCode > 200 || urlResponse.statusCode < 300) else {
                return
            }
            if let data = data {
                if let json = try? NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments){
                        guard let pokemon = PokemonDataProvider.fetchPokemonInBackgroundForID(id) else {
                            return
                        }
                        
                        if let descDictArray = json["descriptions"] as? [[String:AnyObject]] {
                            for descDict in descDictArray {
                                if let languageDict = descDict["language"] as? [String:String] {
                                    if let language = languageDict["name"] where language == "en" {
                                        if let description = descDict["description"] as? String {
                                            pokemon.descriptionString = description
                                            PokemonDataProvider.saveBackgroundContext()
                                            
                                            let note = NSNotification(name: "PokemonDescriptionDidFinishDownloading", object: nil)
                                            
                                            NSNotificationCenter.defaultCenter().postNotification(note)
                                        }
                                    }
                                }
                            }
                        }
                }
            }
        }
        task.resume()
        
    }
    
    static func requestImageForPokemon(pokemon: Pokemon, completion: ((image: UIImage?, error: NSError?) -> Void)?) {
        let url = NSURL(string: pokemon.urlString)!
        let task = session.dataTaskWithURL(url) { (data, response, error) in
            guard let urlResponse = response as? NSHTTPURLResponse where (urlResponse.statusCode > 200 || urlResponse.statusCode < 300) else {
                if let completion = completion {
                    completion(image: nil, error: nil)
                }
                return
            }
            if let error = error {
                if let completion = completion {
                    completion(image: nil, error: error)
                }
                return
            }
            
            if let data = data {
                dispatch_async(dispatch_get_main_queue(), {
                    pokemon.imageData = data
                    PokemonDataProvider.saveMainContext()
                    let image = UIImage(data: data)
                    if let completion = completion {
                        completion(image: image, error: nil)
                    }
                })
            }
        }
        
        task.resume()
    }
    
}
// MARK: Helper for Creating a URL from Parameters

func pokemonURLFromParameters(parameters: [String:AnyObject]?) -> NSURL {
    let components = NSURLComponents()
    
    components.scheme = PokeAPI.Poke.APIScheme
    components.host = PokeAPI.Poke.APIHost
    components.path = PokeAPI.Poke.APIPath
    var queryItems = [NSURLQueryItem]()
    
    if let parameters = parameters {
        for (key, value) in parameters {
            let  queryItem = NSURLQueryItem(name: key, value: "\(value)")
            queryItems.append(queryItem)
        }
        components.queryItems = queryItems
    }
    return components.URL!
    
}
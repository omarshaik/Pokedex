//
//  ImageDetailViewController.swift
//  Pokedex
//
//  Created by IT on 8/19/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import UIKit

class ImageDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
  
    @IBAction func infoButton(sender: UIButton) {
        presentAlert("\(pokemon.name.capitalizedString)", message: "Pokedex number: \(pokemon.id)", actionTitle: "Return")
    }
    var pokemon: Pokemon! {
        didSet {
            PokeAPI.requestPokemonDescriptionForID(pokemon.id.unsignedIntegerValue)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        title = "\(pokemon.name)"
        
        descriptionLabel.text = pokemon.descriptionString
        for type in pokemon.types {
            if typeLabel.text == "" {
                typeLabel.text = type.capitalizedString
            } else {
                if let typeString = typeLabel.text {
                typeLabel.text = typeString + ", " + type.capitalizedString
                }
            }
        }
        
        gradientLayer()
        
        if let image = UIImage(named: "\(pokemon.id)") {
            imageView.image = image
        }
        
        
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(descriptionDownloaded), name: "PokemonDescriptionDidFinishDownloading", object: nil)

        
    }
    
    func descriptionDownloaded() {
        let context = self.pokemon.managedObjectContext
        context?.performBlock({
            context?.refreshAllObjects()
            self.descriptionLabel.text = self.pokemon.descriptionString
        })
    }
    
    private func gradientLayer() {
        let gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [red.aRed.CGColor as CGColorRef, red.bRed.CGColor as CGColorRef]
        gradient.locations = [0.0, 1.0]
        self.view.layer.insertSublayer(gradient, atIndex: 0)
    }

}


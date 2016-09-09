//
//  CollectionViewCell.swift
//  Pokedex
//
//  Created by IT on 8/29/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    var imageView: UIImageView
    override init(frame: CGRect) {
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.topAnchor.constraintEqualToAnchor(contentView.topAnchor).active = true
        imageView.bottomAnchor.constraintEqualToAnchor(contentView.bottomAnchor).active = true
        imageView.leadingAnchor.constraintEqualToAnchor(contentView.leadingAnchor).active = true
        imageView.trailingAnchor.constraintEqualToAnchor(contentView.trailingAnchor).active = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var pokemon: Pokemon? {
        didSet {
            if pokemon == nil {
                imageView.image = nil
                return
            }
            
            if let imageData = pokemon?.imageData {
                let image = UIImage(data: imageData)
                imageView.image = image
            } else {
                if let originalPokemon = pokemon {
                    PokeAPI.requestImageForPokemon(originalPokemon, completion: { (image, error) in
                        if let image = image {
                            if let currentPokemon = self.pokemon {
                                if currentPokemon.id.integerValue == originalPokemon.id.integerValue {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.imageView.image = image
                                    })

                                }
                            }
                        }
                    })
                }
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        pokemon = nil
    }
}
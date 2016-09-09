//
//  CollectionViewController.swift
//  pokedex
//
//  Created by IT on 8/22/16.
//  Copyright © 2016 z0s. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "Cell"

class CollectionViewController: UIViewController {
    
    
    @IBOutlet weak var collectionView: UICollectionView!
    var pokemonArray = [Pokemon]()
    
    let errorMessage = "Looks like there is no connection to the internet!"
    let errorTitle = "No Internet Connection"
    let errorActionTitle = "OK"
    
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Pokedex"
        gradientLayer()
    
        // Register cell classes
        collectionView.delegate = self
        collectionView.dataSource = self
        self.collectionView!.registerClass(CollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        pokemonArray = PokemonDataProvider.fetchPokemon()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(downloadError), name: "PokemonDownloadError", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(dataUpdated), name: NSManagedObjectContextObjectsDidChangeNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(downloadFinished), name: "PokemonDidFinishDownloading", object: nil)

        refreshControl.tintColor = UIColor.grayColor()
        refreshControl.addTarget(self, action: #selector(fetchMorePokemon), forControlEvents: .ValueChanged)
        
        self.collectionView.addSubview(refreshControl)
        self.collectionView.alwaysBounceVertical = true
        
    }
    
    func downloadFinished() {
        dispatch_async(dispatch_get_main_queue()) {
            self.refreshControl.endRefreshing()
        }
    }
    
    func fetchMorePokemon() {
        PokeAPI.fetchNext15Pokemon()
    }
    
    private func gradientLayer() {
        let gradient = CAGradientLayer()
        gradient.frame = self.view.bounds
        gradient.colors = [red.aRed.CGColor as CGColorRef, red.bRed.CGColor as CGColorRef]
        gradient.locations = [0.0, 1.0]
        self.view.layer.insertSublayer(gradient, atIndex: 0)
    }
    
    func downloadError() {
        dispatch_async(dispatch_get_main_queue()) {
            self.presentAlert(self.errorTitle, message: self.errorMessage, actionTitle: self.errorActionTitle)
        }
    }
    
    func dataUpdated() {
        dispatch_async(dispatch_get_main_queue()) {
            self.pokemonArray = PokemonDataProvider.fetchPokemon()
            self.collectionView.reloadData()
        }
    }
}

    // MARK: UICollectionViewDataSource
extension CollectionViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
        
        let pokemon = pokemonArray[indexPath.row]
        cell.pokemon = pokemon
        // Configure the cell
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return pokemonArray.count
    }
    
    
}

// MARK: UICollectionViewDelegate
extension CollectionViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let detailController: ImageDetailViewController = storyboard.instantiateViewControllerWithIdentifier("ImageDetail") as! ImageDetailViewController
        
        let pokemon = pokemonArray[indexPath.row]
        detailController.pokemon = pokemon
        self.navigationController?.pushViewController(detailController, animated: true)
    }
}

extension CollectionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.contentOffset.y == (scrollView.contentSize.height - scrollView.frame.size.height)) {
            //reach bottom
            PokeAPI.fetchNext15Pokemon()
        }
    }
}

 


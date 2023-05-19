//
//  PhotoDataSource.swift
//  Photorama
//
//  Created by csuftitan on 4/11/23.
//

import UIKit

class PhotoDataSource: NSObject, UICollectionViewDataSource {
    
    var showFavorites = false
    
   // private var allPhotos: [Photo] = []
   // private var favoritePhotos: [Photo] = []
    
    var photos = [Photo]()
    
    func favoritePhotos() -> [Photo] {
        var index = 0
        return photos.filter {

            print("photo \(index) \($0.title ?? "N/A")  isFavorite \($0.isFavorite)")
            index += 1
            return $0.isFavorite
        }
     }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let identifier = "PhotoCollectionViewCell"
        let cell =
        collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! PhotoCollectionViewCell
        
        let photo = photos[indexPath.row]
        cell.photoDescription = photo.title
        cell.update(displaying: nil)
        
        cell.iconImage.image = UIImage(systemName: "eye.fill")
       cell.ViewCountLabel.text = "\(photo.viewCount)"
      //  cell.ViewCountLabel.text = "32767" // test display layout for maximum view times
        return cell
    }
    
}

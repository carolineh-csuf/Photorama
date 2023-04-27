//
//  ViewController.swift
//  Photorama
//
//  Created by csuftitan on 4/10/23.
//

import UIKit

class PhotosViewController: UIViewController, UICollectionViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView!
        //  @IBOutlet private var imageView: UIImageView!
    
    //The store is a dependency of the PhotosViewController.Use property injection to give the PhotosViewController its store dependency.Open SceneDelegate.swift and use property injection to give the PhotosViewController an instance of PhotoStore.
    var store: PhotoStore!
    let photoDataSource = PhotoDataSource()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        collectionView.dataSource = photoDataSource
        collectionView.delegate = self
        
        updateDataSource()
        
        store.fetchInterestingPhotos {
            (photosResult) -> Void in
            
            //Printing the results of the request
//            switch photosResult {
//
//            case let .success(photos):
//                print("Successfully found \(photos.count) Interesting Photos.")
//                //                if let firstPhoto = photos.first {
//                //                    self.updateImageView(for: firstPhoto)
//                //                }
//                self.photoDataSource.photos = photos
//            case let .failure(error):
//                print("Error fetching interesting photos: \(error)")
//                self.photoDataSource.photos.removeAll()
//            }
//            self.collectionView.reloadSections(IndexSet(integer: 0))
            
            self.updateDataSource()
        }
        
//        store.fetchRecentPhotos {
//            (photosResult) in
//
//            //Printing the results of the request
//            switch photosResult {
//
//            case let .success(photos):
//                print("Successfully found \(photos.count) RecentPhotos.")
//                if let firstPhoto = photos.first {
//                    //  self.updateImageView(for: firstPhoto)
//                    self.photoDataSource.photos = photos
//                }
//            case let .failure(error):
//                print("Error fetching recent photos: \(error)")
//                self.photoDataSource.photos.removeAll()
//            }
//            self.collectionView.reloadSections(IndexSet(integer: 0))
//        }
    }
    //}
    
    //    func updateImageView(for photo: Photo) {
    //        store.fetchImage(for: photo) {
    //            (imageResult) in
    //
    //            switch imageResult {
    //
    //            case let .success(image):
    //                self.imageView.image = image
    //            case let .failure(error):
    //                print("Error downloading image: \(error)")
    //            }
    //        }
    //    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let photo = photoDataSource.photos[indexPath.row]
        
        //Download the image data, which could take some time
        store.fetchImage(for: photo) { (result) -> Void in
            
            //The index path for the photo might have changed between the time request started and finished ,so find the most recent index path
            guard let photoIndex = self.photoDataSource.photos.firstIndex(of: photo),
                  case let .success(image) = result else {
                return
            }
            
            let photoIndexPath = IndexPath(item: photoIndex, section: 0)
            
            //When the request finished ,find the current cell for this photo
            
            if let cell = self.collectionView.cellForItem(at: photoIndexPath) as? PhotoCollectionViewCell {
                cell.update(displaying: image)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showPhoto":
            if let selectedIndexPath =
                    collectionView.indexPathsForSelectedItems?.first {

                let photo = photoDataSource.photos[selectedIndexPath.row]

                let destinationVC = segue.destination as! PhotoInfoViewController
                destinationVC.photo = photo
                destinationVC.store = store
            }
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }
    
    private func updateDataSource() {
        store.fetchAllPhotos { (photosResult) in
            switch photosResult {
            case let .success(photos):
                self.photoDataSource.photos = photos
            case .failure:
                self.photoDataSource.photos.removeAll()
            }
            self.collectionView.reloadSections(IndexSet(integer: 0))
        }
    }
    
}

extension PhotosViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.size.width/4.15, height: collectionView.frame.size.height/7)
    }
}


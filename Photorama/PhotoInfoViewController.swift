//
//  PhotoInfoViewController.swift
//  Photorama
//
//  Created by csuftitan on 4/11/23.
//

import UIKit

class PhotoInfoViewController: UIViewController {
    
    @IBOutlet var imageView: UIImageView!
    
    @IBOutlet weak var viewCountLabel: UILabel!
    
    @IBOutlet weak var favoriteBarButton: UIBarButtonItem!
    
    var photo: Photo! {
        didSet {
            navigationItem.title = photo.title
        }
    }
    var store: PhotoStore!
    
    
    @IBAction func toggleFavorite(_ sender: UIBarButtonItem) {
     guard let photo = photo else { return }
        
        // Toggle the favorite status
        photo.isFavorite = !photo.isFavorite
        
        do {
            try self.photo.managedObjectContext?.save()
        } catch {
            print("Error saving favorite status: \(error)")
        }
        
        updateFavoriteBarButton()
    }
    
    func updateFavoriteBarButton() {
        guard let photo = photo else { return }
        
        // Set the favorite status of the photo
        let favoriteImage = photo.isFavorite ? UIImage(systemName: "heart.fill") : UIImage(systemName: "heart")
        favoriteBarButton.image = favoriteImage
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.accessibilityLabel = photo.title

        store.fetchImage(for: photo) { (result) -> Void in
            switch result {
            case let .success(image):
                self.imageView.image = image
                self.viewCountLabel.text = "Views: \(self.photo.viewCount)"
                self.favoriteBarButton.isSelected = self.photo.isFavorite
                
                // Increment the view count
                self.photo.viewCount += 1
                
                // Save the managed object context to persist the view count increment
                do {
                    try self.photo.managedObjectContext?.save()
                } catch {
                    print("Error saving view count increment: \(error)")
                }
            case let .failure(error):
                print("Error fetching image for photo: \(error)")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showTags":
            let navController = segue.destination as! UINavigationController
            
            let tagController = navController.topViewController as! TagsViewController
            
            tagController.store = store
            tagController.photo = photo
        default:
            preconditionFailure("Unexpected segue identifier.")
        }
    }
    
}

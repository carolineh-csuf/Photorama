//
//  PhotoCollectionViewCell.swift
//  Photorama
//
//  Created by csuftitan on 4/11/23.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var spinner: UIActivityIndicatorView!
    
    var photoDescription: String?
    
    override var isAccessibilityElement: Bool {
        get {
            return true
        }
        set{
            //Ignore attempts to set
        }
    }
    
    override var accessibilityLabel: String? {
        get {
            return photoDescription
        }
        set{
            //Ignore attemts to set
        }
    }
    
    override var accessibilityTraits: UIAccessibilityTraits {
        get {
            return super.accessibilityTraits.union([.image, .button])
        }
        
        set {
            //Ignore attempts to set
        }
    }
    
    func update(displaying image: UIImage?) {
        if let imageToDisplay = image {
            spinner.stopAnimating()
            imageView.image = imageToDisplay
        } else {
            spinner.startAnimating()
            imageView.image = nil
        }
    }
}

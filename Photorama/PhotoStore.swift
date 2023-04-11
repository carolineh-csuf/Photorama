//
//  PhotoStore.swift
//  Photorama
//
//  Created by csuftitan on 4/10/23.
//

import UIKit

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

class PhotoStore {
    
    //Adding a URLSession property
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    
    func fetchInterestingPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let url = FlickrAPI.interestingPhotoURL
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) {
            (data, response, error) in
            
            //            if let jsonData = data {
            //                if let jsonString = String(data: jsonData, encoding: .utf8) {
            //                    print(jsonString)
            //                }
            //            } else if let requestError = error {
            //                print("Error fetching interesting photos: \(requestError)")
            //            } else {
            //                print("Unexprected error with the request")
            //            }
            
            let result = self.processPhotosRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                //Adding a completion handler
                completion(result)
            }
        }
        task.resume()
    }
    
    //Processing the web service data
    private func processPhotosRequest(data: Data?,
                                      error: Error?) -> Result<[Photo], Error> {
        guard let jsonData = data else {
            return .failure(error!)
        }
        // return FlickrAPI.photos(fromJSON: jsonData)
        return FlickrAPI.photos(fromJSON: jsonData)
    }
    
    func fetchImage(for photo: Photo, completion: @escaping (Result<UIImage, Error>) -> Void) {
        guard let photoURL = photo.remoteURL else {
            completion(.failure(PhotoError.missingImageURL))
            return
        }
        
        //let photoURL = photo.remoteURL
        let request = URLRequest(url: photoURL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
        
            let result =
            self.processImageRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    private func processImageRequest(data: Data?, error: Error?) -> Result<UIImage, Error> {
        guard let imageData = data,
              let image = UIImage(data: imageData) else {
            // coudn't create an image
            if data == nil {
                return .failure(error!)
            } else {
                return .failure(PhotoError.imageCreationError)
            }
        }
        return .success(image)
    }
}

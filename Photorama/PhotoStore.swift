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
    
    let imageStore = ImageStore()
    
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
            guard let httpURLResponse = response as? HTTPURLResponse else {
                print("fetchInterestingPhotos Invalid response")
                return
            }
            
            print("fetchInterestingPhotos Status code: \(httpURLResponse.statusCode)")
            print("fetchInterestingPhotos All header fields: \(httpURLResponse.allHeaderFields)")
            print()
            
            let result = self.processPhotosRequest(data: data, error: error)
            OperationQueue.main.addOperation {
                //Adding a completion handler
                completion(result)
            }
        }
        
        task.resume()
    }
    
    
   func fetchRecentPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
    let url = FlickrAPI.recentPhotoURL
    let request = URLRequest(url: url)
    let task = session.dataTask(with: request) {
        (data, response, error) in
        
        guard let httpURLResponse = response as? HTTPURLResponse else {
            print("fetchRecentPhotos Invalid response")
            return
        }
        
        print("fetchRecentPhotos Status code: \(httpURLResponse.statusCode)")
        print("fetchRecentPhotos All header fields: \(httpURLResponse.allHeaderFields)")
        print()
        
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
        
        //Using the image store to cache images
        let photoKey = photo.photoID
        if let image = imageStore.image(forKey: photoKey) {
            OperationQueue.main.addOperation {
                completion(.success(image))
            }
            return
        }
        
        guard let photoURL = photo.remoteURL else {
            completion(.failure(PhotoError.missingImageURL))
            return
        }
        
        //let photoURL = photo.remoteURL
        let request = URLRequest(url: photoURL)
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
        
//            guard let httpURLResponse = response as? HTTPURLResponse else {
//                print("fetchImage: Invalid response")
//                return
//            }
//
//            print("fetchImage Status code: \(httpURLResponse.statusCode)")
//            print("fetchImage All header fields: \(httpURLResponse.allHeaderFields)")

            let result =
            self.processImageRequest(data: data, error: error)
            
            if case let .success(image) = result {
                self.imageStore.setImage(image, forKey: photoKey)
            }
            
            OperationQueue.main.addOperation {
                completion(result)
            }
        }
        task.resume()
    }
    
    // Processing the image request data
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

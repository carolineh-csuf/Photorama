//
//  PhotoStore.swift
//  Photorama
//
//  Created by csuftitan on 4/10/23.
//

import UIKit
import CoreData

enum PhotoError: Error {
    case imageCreationError
    case missingImageURL
}

class PhotoStore {
    
    let imageStore = ImageStore()
    
    let persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Photorama")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error setting up Core Data (\(error)).")
            }
        }
        return container
    }()
    
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
            
            //let result = self.processPhotosRequest(data: data, error: error)
            //            var result = self.processPhotosRequest(data: data, error: error)
            //            if case .success = result {
            //                do {
            //                    try self.persistentContainer.viewContext.save()
            //                } catch {
            //                    result = .failure(error)
            //                }
            //            }
            //
            //            OperationQueue.main.addOperation {
            //                //Adding a completion handler
            //                completion(result)
            //            }
            
            self.processPhotosRequest(data: data, error: error) {
                (result) in
                
                OperationQueue.main.addOperation {
                    completion(result)
                }
            }
            
        }
        //Tasks are always created in the suspended state,
        //so calling resume() on the task will start the web service request.
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
            
            //        let result = self.processPhotosRequest(data: data, error: error)
            //        OperationQueue.main.addOperation {
            //            //Adding a completion handler
            //            completion(result)
            //        }
            self.processPhotosRequest(data: data, error: error) {
                (result) in
                
                OperationQueue.main.addOperation {
                    completion(result)
                }
            }
        }
        
        task.resume()
    }
    
    //Processing the web service data
    private func processPhotosRequest(data: Data?,
                                      //                                  error: Error?) -> Result<[Photo], Error> {
                                      error: Error?, completion: @escaping (Result<[Photo],Error>) -> Void) {
        guard let jsonData = data else {
            // return .failure(error!)
            completion(.failure(error!))
            return
        }
        // return FlickrAPI.photos(fromJSON: jsonData)
        
        //let context = persistentContainer.viewContext
        
        persistentContainer.performBackgroundTask { (context) in
            
            switch FlickrAPI.photos(fromJSON: jsonData) {
            case let .success(flickrPhotos):
                let photos = flickrPhotos.map { flickrPhoto -> Photo in
                    
                    let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
                    let predicate = NSPredicate(
                        format: "\(#keyPath(Photo.photoID)) == \(flickrPhoto.photoID)")
                    fetchRequest.predicate = predicate
                    var fetchedPhotos: [Photo]?
                    context.performAndWait {
                        fetchedPhotos = try? fetchRequest.execute()
                    }
                    if let existingPhoto = fetchedPhotos?.first {
                        return existingPhoto
                    }
                    
                    var photo: Photo!
                    context.performAndWait {
                        photo = Photo(context: context)
                        photo.title = flickrPhoto.title
                        photo.photoID = flickrPhoto.photoID
                        photo.remoteURL = flickrPhoto.remoteURL
                        photo.dateTaken = flickrPhoto.dateTaken
                    }
                    return photo
                }
                
                do {
                    try context.save()
                } catch {
                    print("Error saving to Core Data: \(error).")
                    completion(.failure(error))
                    return
                }
                //return .success(photos)
                //completion(.success(photos))
                
                let photoIDs = photos.map { $0.objectID }
                let viewContext = self.persistentContainer.viewContext
                let viewContextPhotos = photoIDs.map { viewContext.object(with: $0) } as! [Photo]
                completion(.success(viewContextPhotos))
            case let .failure(error):
                //return .failure(error)
                completion(.failure(error))
            }
        }
    }
    
    func fetchImage(for photo: Photo, completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        //Using the image store to cache images
        //let photoKey = photo.photoID
        guard let photoKey = photo.photoID else {
            preconditionFailure("Photo expected to have a photoID")
        }
        
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
    
    //fetch all photos from disk
    func fetchAllPhotos(completion: @escaping (Result<[Photo], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortByDateTaken = NSSortDescriptor(key: #keyPath(Photo.dateTaken), ascending: true)
        fetchRequest.sortDescriptors = [sortByDateTaken]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allPhotos = try viewContext.fetch(fetchRequest)
                completion(.success(allPhotos))
                
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // fetch all tags
    func fetchAllTags(completion: @escaping (Result<[Tag], Error>) -> Void) {
        let fetchRequest: NSFetchRequest<Tag> = Tag.fetchRequest()
        let sortByName = NSSortDescriptor(key: #keyPath(Tag.name), ascending: true)
        fetchRequest.sortDescriptors = [sortByName]
        
        let viewContext = persistentContainer.viewContext
        viewContext.perform {
            do {
                let allTags = try fetchRequest.execute()
                completion(.success(allTags))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

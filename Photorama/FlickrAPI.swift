//
//  FlickrAPI.swift
//  Photorama
//
//  Created by csuftitan on 4/10/23.
//

import Foundation

enum EndPoint: String {
    case interestingPhotos = "flickr.interestingness.getList"
    case recentPhotos = "flickr.photos.getRecent"
}
//Defining the response structures
struct FlickrResponse: Codable {
    let photosInfo: FlickrPhotoResponse
    
    enum CodingKeys: String, CodingKey {
        case photosInfo = "photos"
    }
}

struct FlickrPhotoResponse: Codable {
    let photos: [FlickrPhoto]
    
    enum CodingKeys: String, CodingKey {
        case photos = "photo"
    }
}

struct FlickrAPI {
    //Adding the base URL for the Flickr requests
    private static let baseURLString = "https://api.flickr.com/services/rest"
    //Adding an API key property
    private static let apiKey = "a6d819499131071f158fd740860a5a88"
    
    
    //return a Flickr URL
    private static func flickrURL(endPoint: EndPoint, parameters: [String:String]?) -> URL {
        
        //Adding the additional parameters to the URL
        var components = URLComponents(string: baseURLString)!
        var queryItems = [URLQueryItem]()
        
        //Adding the shared parameters to the URL
        let baseParams = [
            "method": endPoint.rawValue,
            "format": "json",
            "nojsoncallback": "1",
            "api_key": apiKey
        ]
        
        for (key, value) in baseParams {
            let item = URLQueryItem(name: key, value: value)
            queryItems.append(item)
        }
        
        if let additionalParams = parameters {
            for (key, value) in additionalParams {
                let item = URLQueryItem(name: key, value: value)
                queryItems.append(item)
            }
        }
        components.queryItems = queryItems
        
        //return URL(string: "")!
        return components.url!
    }
    
    // Exposing a URL for interesting photos
    static var interestingPhotoURL: URL {
        return flickrURL(endPoint: .interestingPhotos, parameters: ["extras": "url_z,date_taken"])
    }
    
    // Exposing a URL for recent photos
    static var recentPhotoURL: URL {
        return flickrURL(endPoint: .recentPhotos, parameters: ["extras": "url_z,date_taken"])
    }
    
    
    static func photos(fromJSON data: Data) -> Result<[FlickrPhoto], Error> {
        do {
            let decoder = JSONDecoder()
            
            //Adding a custom date decoding strategy
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let flickrResponse = try decoder.decode(FlickrResponse.self, from: data)
            
            // Filtering out photos with a missing URL
            //            return .success(flickrResponse.photosInfo.photos)
            let photos = flickrResponse.photosInfo.photos.filter { $0.remoteURL != nil }
            return .success(photos)
        } catch {
            return .failure(error)
        }
    }
    
    
    
}


//
//  FlickrAPI.swift
//  Photorama
//
//  Created by csuftitan on 4/10/23.
//

import Foundation

enum EndPoint: String {
    case interestinghotos = "flickr.interestingness.getList"
}

struct FlickrAPI {
    
    private static let baseURLString = "https://api.flickr.com/services/rest"

    private static let apiKey = "a6d819499131071f158fd740860a5a88"

    private static func flickrURL(endPoint: EndPoint, parameters: [String:String]?) -> URL {
        
        var components = URLComponents(string: baseURLString)!
        var queryItems = [URLQueryItem]()
        
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
    
    static var interestingPhotoURL: URL {
        return flickrURL(endPoint: .interestinghotos, parameters: ["extras": "url_z,date_taken"])
    }
    
    
}


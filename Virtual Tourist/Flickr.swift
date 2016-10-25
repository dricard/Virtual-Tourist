//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-25.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import Foundation

struct Flickr {
   
   // API related
   static let FlickrBaseURL = "https://api.flickr.com/services/rest/"
   static let PhotoSearchMethod = "flickr.photos.search"
   static let PhotoSearchRadius = "2"
   static let Photos = "photos"
   static let Photo = "photo"
   
   // Dictionary keys
   static let Title = "title"
   static let ID = "id"
   static let ImagePath = "url_m"
   
   // Error codes
   static let networkError = 1
   static let requestError = 2
   static let noDataError = 3
   static let parseError = 4
   static let noPhotoDataError = 5
}

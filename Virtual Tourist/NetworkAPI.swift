//
//  NetworkAPI.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-25.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import UIKit
import MapKit

class NetworkAPI: NSObject {
   
   // MARK: - Properties
   
   // MARK: - Network request
   
   static func sendRequest(_ pin: Pin, completionHandlerForNetworkRequest: @escaping (_ photosDict: [[String:AnyObject]]?, _ success: Bool, _ error: NSError?) -> Void) {
      
      let session = URLSession.shared
      
      // 1. create the parameters dictionary
      let URLParams = [
         "method": Flickr.PhotoSearchMethod,
         "lat": "\(pin.lat)",
         "lon": "\(pin.lon)",
         "format": "json",
         "extras": "url_m",
         "nojsoncallback": "1",
         "api_key": APIKey.Flickr_API_KEY,
         "radius": Flickr.PhotoSearchRadius
      ]
      
      // 2. Build URL
      guard var URL = URL(string: Flickr.FlickrBaseURL) else { return }
      URL = URL.URLByAppendingQueryParameters(URLParams)
      
      print(URL)
      
      // 3. configure the request
      let request = NSMutableURLRequest(url: URL)
      request.httpMethod = "GET"
      
      // 4. Make the request
      let task = session.dataTask(with: request as URLRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) in
         
         // Utility function
         func sendError(_ error: String, code: Int) {
            print("Error: \(error), code: \(code)")
            // build informative NSError to return
            let userInfo = [NSLocalizedDescriptionKey: error]
            completionHandlerForNetworkRequest(nil, false, NSError(domain: "sendRequest", code: code, userInfo: userInfo))
         }
         
         // GUARD: was there an error returned by the URL request?
         guard error == nil else {
            sendError("Flickr API returned an error: \(error)", code: Flickr.networkError)
            return
         }
         
         // GUARD: did we get a successful 2XX response?
         guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            let theStatusCode = (response as? HTTPURLResponse)?.statusCode
            sendError("Flickr returned a status code outside the success range: \(theStatusCode)", code: Flickr.requestError)
            return
         }
         
         // GUARD: was there data returned?
         guard let data = data else {
            sendError("No data returned by the request!", code: Flickr.noDataError)
            return
         }
         
         // 5. parse the data
         
         let parsedResult = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
   
         // 6. use the data
         
         // GUARD: get the photos root obkect from the parse data
         guard let photoElement = parsedResult??[Flickr.Photos] as? [String:AnyObject] else {
            sendError("Could not parse photos from the data", code: Flickr.noPhotoDataError)
            return
         }
         
         // now get the photos array from that root object
         guard let photoArray = photoElement[Flickr.Photo] as? [[String:AnyObject]] else {
            sendError("Could not parse photo from the data", code: Flickr.noPhotoDataError)
            return
         }
         
         completionHandlerForNetworkRequest(photoArray, true, nil)
         
         
      }).resume()
      
   }
}


protocol URLQueryParameterStringConvertible {
   var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
   
   /// This computed property returns a query parameters string from the given NSDictionary.
   /// - note: For example, if the input is @{@"day":@"Tuesday", @"month":@"January"}, the output
   /// string will be @"day=Tuesday&month=January".
   /// - returns:
   ///     - The computed parameters string.
   var queryParameters: String {
      var parts: [String] = []
      for (key, value) in self {
         let part = NSString(format: "%@=%@",
                             String(describing: key).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!,
                             String(describing: value).addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
         parts.append(part as String)
      }
      return parts.joined(separator: "&")
   }
   
}

extension URL {
   
   /// Creates a new URL by adding the given query parameters.
   /// - parameters:
   ///     - parametersDictionary The query parameter dictionary to add.
   /// - returns:
   ///     - A new NSURL.
   func URLByAppendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
      let URLString : NSString = NSString(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
      return URL(string: URLString as String)!
   }
}

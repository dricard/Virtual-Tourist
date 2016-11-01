//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Denis Ricard on 2016-10-27.
//  Copyright © 2016 Hexaedre. All rights reserved.
//

import Foundation
import CoreData

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var id: String?
    @NSManaged public var imageURL: String?
    @NSManaged public var title: String?
    @NSManaged public var image: Data?
    @NSManaged public var pin: Pin?

}

//
//  YouTubeVideo+CoreDataProperties.swift
//  
//
//  Created by Sachin Vas on 7/29/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension YouTubeVideo {

    @NSManaged var videoId: String?
    @NSManaged var publishedAt: NSDate?
    @NSManaged var title: String?
    @NSManaged var videoDescription: String?
    @NSManaged var thumbnailPath: String?
    @NSManaged var position: NSNumber?

}

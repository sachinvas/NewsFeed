//
//  BlogItem+CoreDataProperties.swift
//  
//
//  Created by Sachin Vas on 7/18/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BlogItem {

    @NSManaged var blogDescription: String?
    @NSManaged var blogId: NSNumber?
    @NSManaged var commentRssURL: String?
    @NSManaged var comments: NSNumber?
    @NSManaged var commentsURL: String?
    @NSManaged var creator: String?
    @NSManaged var guid: String?
    @NSManaged var linkURL: String?
    @NSManaged var publicationDate: NSDate?
    @NSManaged var title: String?
    @NSManaged var categories: NSSet?

}

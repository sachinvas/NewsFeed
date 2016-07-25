//
//  BlogPreviewItem+CoreDataProperties.swift
//  
//
//  Created by Sachin Vas on 7/25/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension BlogPreviewItem {

    @NSManaged var avatar: NSData?
    @NSManaged var blogItem: BlogItem?
    @NSManaged var account: Account?

}

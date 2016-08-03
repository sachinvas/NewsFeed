//
//  Pin+CoreDataProperties.swift
//  
//
//  Created by Sachin Vas on 8/2/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var boardId:String?
    @NSManaged var creationTime: NSDate?
    @NSManaged var pinId: String?
    @NSManaged var name: String?
    @NSManaged var descriptionText: String?
    @NSManaged var link: String?
    @NSManaged var imageURL: String?

}

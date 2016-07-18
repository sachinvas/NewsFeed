//
//  Category+CoreDataProperties.swift
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

extension Category {

    @NSManaged var name: String?
    @NSManaged var blogId: BlogItem?

}

//
//  Contact+CoreDataProperties.swift
//  
//
//  Created by Sachin Vas on 7/30/16.
//
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Contact {

    @NSManaged var placeName: String?
    @NSManaged var address: String?
    @NSManaged var phoneNumber: String?
    @NSManaged var emailId: String?
    @NSManaged var longitude: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var mapURL: String?

}

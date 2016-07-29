//
//  Account+CoreDataProperties.swift
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

extension Account {

    @NSManaged var accountId: NSNumber?
    @NSManaged var emailId: String?
    @NSManaged var name: String?
    @NSManaged var userName: String?
    @NSManaged var accountDetails: AnyObject?

    override static func initialize() {
        if self.isKindOfClass(Account) {
            let transformer = AccountPasswordTransformer()
            NSValueTransformer.setValueTransformer(transformer, forName:"AccountPasswordTransformer");
        }
    }
}

class AccountPasswordTransformer: NSValueTransformer {
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        return nil
    }
}
//
//  NDNewsItemController.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import CoreData


class NDNewsItemController: NSObject {
    var managedObjectContext: NSManagedObjectContext!
    init(moc: NSManagedObjectContext) {
        managedObjectContext = moc
        super.init()
    }
    
    func insertObject(objectDictionary: Dictionary<String, AnyObject>) {
        let blogItem:BlogItem = NSEntityDescription.insertNewObjectForEntityForName("BlogItem", inManagedObjectContext: managedObjectContext) as! BlogItem
        blogItem.linkURL = objectDictionary["link"] as? String
        blogItem.title = objectDictionary["title"] as? String
        blogItem.creator = objectDictionary["dc:creator"] as? String
        blogItem.guid = objectDictionary["guid"] as? String
        if let guid = objectDictionary["guid"] as? String {
            let subStrings = guid.componentsSeparatedByString("=")
            if subStrings.count > 1 {
                blogItem.blogId = Int(subStrings[1])
            }
        }
        blogItem.commentsURL = objectDictionary["comments"] as? String
        blogItem.blogDescription = objectDictionary["description"] as? String
        blogItem.commentRssURL = objectDictionary["wfw:commentRss"] as? String
        if let numOfCommentsString = objectDictionary["slash:comments"] as? String {
            if let numOfComments = Int(numOfCommentsString) {
                blogItem.comments = NSNumber(integer: numOfComments)
            }
        }
        if let dateString = objectDictionary["pubDate"] as? String {
            blogItem.publicationDate = NDUtility.utility.newsDateFormatter.dateFromString(dateString)
        }
        
        var categories:[Category] = []
        if let categorieObjects = objectDictionary["categories"] as? Array<String> {
            if categorieObjects.count > 0 {
                for categoryName in categorieObjects {
                    let category:Category = NSEntityDescription.insertNewObjectForEntityForName("Category", inManagedObjectContext: managedObjectContext) as! Category
                    category.name = categoryName
                    categories.append(category)
                }
                blogItem.categories = NSSet(array: categories)
            }
        }
    }
    
    func checkIfObjectExistInDatabaseForguid(guid: NSString) -> Bool {
        var objectExist:Bool = false
        let subStrings = guid.componentsSeparatedByString("=")
        if subStrings.count > 1 {
            if let blogId = Int(subStrings[1]) {
                let fetchRequest = NSFetchRequest(entityName: "BlogItem")
                fetchRequest.predicate = NSPredicate(format: "blogId = %d", blogId)
                fetchRequest.resultType = .CountResultType
                do {
                    if let result = try managedObjectContext.executeRequest(fetchRequest) as? NSAsynchronousFetchResult {
                        if let resultArray = result.finalResult {
                            objectExist = resultArray[0] as! Int > 0
                        }
                    }
                } catch let error {
                    print(error)
                }
            }
        }
        return objectExist
    }
    
    func saveMoc() {
        do {
            try managedObjectContext.save()
            var context = managedObjectContext.parentContext
            while context != nil {
                try context?.save()
                context = context?.parentContext
            }
        } catch let errorType {
            print(errorType)
        }
    }
}
//
//  NDNewsItemController.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import CoreData
import iOS_GTLYouTube
import hpple

class NDNewsItemController: NSObject {
    var managedObjectContext: NSManagedObjectContext!
    init(moc: NSManagedObjectContext) {
        managedObjectContext = moc
        super.init()
    }
    
    func insertBlogObject(objectDictionary: Dictionary<String, AnyObject>) {
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
    
    func insertYouTubeVideoObject(snippet:GTLYouTubePlaylistItemSnippet, videoId: String) {
        let youTubeVideo:YouTubeVideo = NSEntityDescription.insertNewObjectForEntityForName("YouTubeVideo", inManagedObjectContext: managedObjectContext) as! YouTubeVideo
        youTubeVideo.position = snippet.position
        youTubeVideo.title = snippet.title
        youTubeVideo.videoDescription = snippet.descriptionProperty
        youTubeVideo.videoId = videoId
        youTubeVideo.publishedAt = snippet.publishedAt.date
        youTubeVideo.thumbnailPath = (snippet.thumbnails.additionalPropertyForName("medium") as? GTLYouTubeThumbnail)?.url
    }
    
    func insertContactObject(contactElement:TFHppleElement, mapURLString: String) {
        let contact:Contact = NSEntityDescription.insertNewObjectForEntityForName("Contact", inManagedObjectContext: managedObjectContext) as! Contact
        //Second element contains the name information...
        if contactElement.children.count > 1 {
            if let element = contactElement.children[1] as? TFHppleElement {
                //Zero element name of the city...
                if element.children.count > 0 {
                    if let nameElement = element.children[0] as? TFHppleElement {
                        contact.placeName = nameElement.content
                    }
                }
            }
        }
        //Third element contains the address information...
        if contactElement.children.count > 3 {
            if let element = contactElement.children[3] as? TFHppleElement {
                //Zero element Area...
                if element.children.count > 0 {
                    if let areaElement = element.children[0] as? TFHppleElement {
                        contact.address = areaElement.content
                    }
                }
                //Second element Address...
                if element.children.count > 2 {
                    if let addressElement = element.children[2] as? TFHppleElement {
                        contact.address = contact.address! + addressElement.content
                    }
                }
                //Fifth element phoneNumber
                if element.children.count > 5 {
                    if let phoneNumberElement = element.children[5] as? TFHppleElement {
                        contact.phoneNumber = phoneNumberElement.attributes!["href"] as? String
                    }
                }
                //Fifth element emailId
                if element.children.count > 8 {
                    if let emailIdElement = element.children[8] as? TFHppleElement {
                        contact.emailId = emailIdElement.attributes!["href"] as? String
                    }
                }
            }
        }
        contact.mapURL = mapURLString
        let llArray = mapURLString.componentsSeparatedByString("&")
        if llArray.count > 1 {
            let latLongCombined = llArray[1].componentsSeparatedByString("=")
            if latLongCombined.count > 1 {
                let latLongSeperated = latLongCombined[1].componentsSeparatedByString(",")
                if latLongSeperated.count > 0 && latLongSeperated[0].characters.count > 0 {
                    contact.latitude = NSNumber(double: Double(latLongSeperated[0])!)
                }
                if latLongSeperated.count > 1 && latLongSeperated[1].characters.count > 1 {
                    contact.longitude = NSNumber(double: Double(latLongSeperated[1])!)
                }
            }
        }
    }

    func checkIfObjectExistInDatabase(entityName:String, predicate: NSPredicate) -> Bool {
        var objectExist:Bool = false
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
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
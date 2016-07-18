//
//  NDNewtworkManager.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import Alamofire

class NDNetworkManager: NSObject {
    
    class var sharedManager: NDNetworkManager {
        struct Singleton {
            static let instance = NDNetworkManager()
        }
        return Singleton.instance
    }
    
    func fetchDataLiciousBlogFeeds(completionBlock: (Bool)->()) {
        performAPICall("http://blog.datalicious.com/feed/", method: nil, parameters: nil) { (success: Bool, data: NSData?) in
            if success {
                let blogItemParser = NDBlogItemParser(xmlData: data!)
                blogItemParser.parse()
                let newsItemController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                for blogItemDictionary in blogItemParser.blogItems {
                    newsItemController.insertObject(blogItemDictionary)
                }
                newsItemController.saveMoc()
            }
            completionBlock(success)
        }
    }
    
    func performAPICall(urlString: String, method: String?, parameters: [String: AnyObject]?, withCompletionBlock completionBlock: (Bool, NSData?)->()) {
        Alamofire.request(.GET, urlString, parameters: nil)
            .response { (request, response, data, error) in
                if error == nil {
                    completionBlock(true, data)
                } else {
                    completionBlock(false, nil)
                }
        }
    }
}

//
//  NDNewtworkManager.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import Alamofire
import TwitterKit

class NDNetworkManager: NSObject {
    
    class var sharedManager: NDNetworkManager {
        struct Singleton {
            static let instance = NDNetworkManager()
        }
        return Singleton.instance
    }
    
    func fetchTweets(completionBlock: (Bool, String?)->()) {
        Twitter.sharedInstance().logInWithMethods([.WebBased]) {[weak self](session, error) in
            if let unwrappedSession = session {
                self?.searchTweets(["q":"from@datalicious"], completionBlock: { (success, tweets) in
                    
                })
            } else {
                NSLog("Login error: %@", error!.localizedDescription);
                completionBlock(false, nil)
            }
       }
    }
    
    func searchTweets(params: [NSObject:AnyObject], completionBlock: (Bool, [TWTRTweet]?)->()) {
        let client = TWTRAPIClient()
        let statusesShowEndpoint = "https://api.twitter.com/1.1/search/tweets.json"
        var clientError : NSError?
        
        let request = client.URLRequestWithMethod("GET", URL: statusesShowEndpoint, parameters: params, error: &clientError)
        
        client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if connectionError != nil {
                print("Error: \(connectionError)")
                completionBlock(false, nil)
            }
            
            if data != nil {
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                    if let jsonArray = json["statuses"] as? [AnyObject] where jsonArray.count > 0 {
                        if let tweets = TWTRTweet.tweetsWithJSONArray(jsonArray) as? Array<TWTRTweet> {
                            completionBlock(true, tweets)
                        } else {
                            print("Unable to convert to tweets")
                            completionBlock(false, nil)
                        }
                    } else {
                        print("No tweets")
                        completionBlock(false, nil)
                    }
                } catch let jsonError as NSError {
                    print("json error: \(jsonError.localizedDescription)")
                    completionBlock(false, nil)
                }
            }
        }
    }

    func fetchDataLiciousBlogFeeds(completionBlock: (Bool)->()) {
        performAPICall("http://blog.datalicious.com/feed/", method: nil, parameters: nil) { (success: Bool, data: NSData?) in
            if success {
                let blogItemParser = NDBlogItemParser(xmlData: data!)
                blogItemParser.parse()
                let newsItemController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                for blogItemDictionary in blogItemParser.blogItems {
                    if newsItemController.checkIfObjectExistInDatabaseForguid(blogItemDictionary["guid"] as! String) == false {
                        newsItemController.insertObject(blogItemDictionary)
                    }
                }
                newsItemController.saveMoc()
            }
            completionBlock(success)
        }
    }
    
    func getContactDetailsFromDatalicicous(completionBlock: (Bool)->()) {
        performAPICall("http://www.datalicious.com/contact/", method: nil, parameters: nil) { (success:Bool, data:NSData?) in
            
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

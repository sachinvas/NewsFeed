//
//  NDNewtworkManager.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import CoreFoundation
import AFNetworking
import TwitterKit
import GoogleSignIn
import iOS_GTLYouTube
import hpple

let googleAPIKey = "AIzaSyA-X_X4yS9ZMNUGjU_yo2EgYgqyJm4ZWqc"

class NDNetworkManager: NSObject {
    
    private var gtlServiceYouTube: GTLServiceYouTube!
    private var newtworkQueue: NSOperationQueue!
    
    class var sharedManager: NDNetworkManager {
        struct Singleton {
            static let instance = NDNetworkManager()
        }
        return Singleton.instance
    }
    
    private override init() {
        gtlServiceYouTube = GTLServiceYouTube()
        gtlServiceYouTube.APIKey = googleAPIKey
        newtworkQueue = NSOperationQueue()
        newtworkQueue.qualityOfService = .Background
    }
    
    // MARK: blogs from datalicious...
    func fetchDataLiciousBlogFeeds(completionBlock: (Bool, NSError?)->()) {
        performAPICall("http://blog.datalicious.com/feed/", method: nil, parameters: [:]) { (success: Bool, data: NSData?, error: NSError?) in
            if success {
                let blogItemParser = NDBlogItemParser(xmlData: data!)
                blogItemParser.parse()
                let newsItemController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                for blogItemDictionary in blogItemParser.blogItems {
                    let blogId = (blogItemDictionary["guid"] as! String).componentsSeparatedByString("=")[1]
                    let predicate = NSPredicate(format: "blogId=%@", blogId)
                    if newsItemController.checkIfObjectExistInDatabase("BlogItem", predicate:predicate) == false {
                        newsItemController.insertBlogObject(blogItemDictionary)
                    }
                }
                newsItemController.saveMoc()
            }
            completionBlock(success, error)
        }
    }
    
    // MARK: tweets from user account...
    func fetchTweets(completionBlock: (Bool, String?, NSError?)->()) {
        var count = 0
        count = count + 1
        var overAllTweets: [TWTRTweet] = []
        var overAllError: NSError?
        var overAllSuccess: Bool = false
        searchTweets(["q":"from:datalicious"], completionBlock: { (success, tweets, error) in
            overAllSuccess = success
            overAllError = error
            if let tweets = tweets {
                if overAllTweets.count == 0 {
                    overAllTweets = tweets
                } else {
                    overAllTweets = overAllTweets + tweets
                }
            }
            count = count - 1
        })
        while count != 0 {
        }
        count = count + 1
        searchTweets(["q":"from:cbartens"], completionBlock: { (success, tweets, error) in
            overAllSuccess = success
            overAllError = error
            if let tweets = tweets {
                if overAllTweets.count == 0 {
                    overAllTweets = tweets
                } else {
                    overAllTweets = overAllTweets + tweets
                }
            }
            count = count - 1
        })
        while count != 0 {
        }
        count = count + 1
        searchTweets(["q":"from:thesupertag"], completionBlock: { (success, tweets, error) in
            overAllSuccess = success
            overAllError = error
            if let tweets = tweets {
                if overAllTweets.count == 0 {
                    overAllTweets = tweets
                } else {
                    overAllTweets = overAllTweets + tweets
                }
            }
            count = count - 1
        })
        while count != 0 {
        }
        if overAllTweets.count > 0 {
            var filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            filePath = filePath + "/Tweets"
            let success = NSKeyedArchiver.archiveRootObject(overAllTweets, toFile: filePath)
            completionBlock(success, (overAllSuccess ? filePath : nil), overAllError)
        } else {
            completionBlock(overAllSuccess, nil, overAllError)
        }
    }

    func searchTweets(params: [NSObject:AnyObject], completionBlock: (Bool, [TWTRTweet]?, NSError?)->()) {
        dispatch_async(dispatch_get_main_queue()) {
            let client = TWTRAPIClient()
            let statusesShowEndpoint = "https://api.twitter.com/1.1/search/tweets.json"
            var clientError : NSError?
            
            let request = client.URLRequestWithMethod("GET", URL: statusesShowEndpoint, parameters: params, error: &clientError)
            
            client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
                if connectionError != nil {
                    print("Error: \(connectionError)")
                    completionBlock(false, nil, connectionError)
                }
                
                if data != nil {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: [])
                        if let jsonArray = json["statuses"] as? [AnyObject] where jsonArray.count > 0 {
                            if let tweets = TWTRTweet.tweetsWithJSONArray(jsonArray) as? Array<TWTRTweet> {
                                completionBlock(true, tweets, nil)
                            } else {
                                print("Unable to convert to tweets")
                                let userInfo = ["NSLocalizedDescriptionKey": "Twitter response is improper"]
                                let error = NSError(domain: "com.datalicious.news", code: 1, userInfo: userInfo)
                                completionBlock(false, nil, error)
                            }
                        } else {
                            print("No tweets")
                            completionBlock(true, nil, nil)
                        }
                    } catch let jsonError as NSError {
                        print("json error: \(jsonError.localizedDescription)")
                        completionBlock(false, nil, jsonError)
                    }
                }
            }
        }
    }
    
    
    // MARK: YouTube videos
    func getYouTubeDataliciousVideos(completionBlock:(Bool, NSError?)->()) {
        getYoutubeDataliciousUploadPlaylistId {[unowned self] (success:Bool, playlistid:String?, error:NSError?) in
            if success {
                if let id = playlistid {
                    var pageToken:String? = nil
                    while true {
                        var count:Int = 1
                        self.getYouTubeVideosForPlaylistItemId(id, pageToken: pageToken, completionBlock: { (success:Bool, nextPageToken:String?, error: NSError?) in
                            if success {
                                pageToken = nextPageToken
                            }
                            count = count - 1
                        })
                        while count != 0 {
                        }
                        if pageToken == nil {
                            break
                        }
                    }
                    completionBlock(true, nil)
                } else {
                    let userInfo = ["NSLocalizedDescriptionKey": "PlaylistId is valid"]
                    let error = NSError(domain: "com.datalicious.news", code: 1002, userInfo: userInfo)
                    completionBlock(false, error)
                }
            } else {
                print(error)
                completionBlock(false, error)
            }
        }
    }
        
    private func getYouTubeVideosForPlaylistItemId(playlistItemId:String, pageToken:String?, completionBlock:(Bool, String?, NSError?)->()) {
        dispatch_async(dispatch_get_main_queue()) {[unowned self] in
            var playlistItemURLString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet%2CcontentDetails&playlistId=\(playlistItemId)&"
            playlistItemURLString = playlistItemURLString + (pageToken != nil ? "pageToken=\(pageToken!)&key=\(googleAPIKey)" : "key=\(googleAPIKey)")
            let playlistItemURL = NSURL(string: playlistItemURLString)
            self.gtlServiceYouTube.fetchObjectWithURL(playlistItemURL, completionHandler: { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self.newtworkQueue.addOperationWithBlock({
                    if error == nil {
                        if let listResponse = object as? GTLYouTubePlaylistItemListResponse {
                            if let items = listResponse.items() as? Array<GTLYouTubePlaylistItem> {
                                let newsItemController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                                for playlist in items {
                                    let videoId = playlist.contentDetails.videoId
                                    let predicate = NSPredicate(format: "videoId = %@", videoId)
                                    if !newsItemController.checkIfObjectExistInDatabase("YouTubeVideo", predicate: predicate) {
                                        newsItemController.insertYouTubeVideoObject(playlist.snippet, videoId: videoId)
                                    }
                                }
                                newsItemController.saveMoc()
                                completionBlock(true, listResponse.nextPageToken, nil)
                            } else {
                                print("No items found")
                                completionBlock(true, nil, nil)
                            }
                        } else {
                            let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                            let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                            completionBlock(false, nil, error)
                        }
                    } else {
                        print(error)
                        completionBlock(false, nil, error)
                    }
                })
            })
        }
    }
    
    private func getYoutubeDataliciousUploadPlaylistId(completionBlock: (Bool, String?, NSError?)->()) {
        getAllRelatedPlayListsOfDataliciousFromYouTube {[unowned self] (success:Bool, relatedPlaylist:GTLYouTubeChannelContentDetailsRelatedPlaylists?, error: NSError?) in
            if success {
                var count:Int = 1
                var uploadPlaylist: GTLYouTubePlaylist! = nil
                self.newtworkQueue.addOperationWithBlock({
                    self.getPlaylistItemForplaylistId(relatedPlaylist!.uploads, completionBlock: { (success:Bool, obtainedPlaylist:GTLYouTubePlaylist?, error: NSError?) in
                        if success {
                            if let playlist = obtainedPlaylist {
                                uploadPlaylist = playlist
                            }
                        }
                        count = count - 1
                    })
                })
                while count != 0 {
                }
                if let uploadPlaylistId = uploadPlaylist.identifier {
                    completionBlock(true, uploadPlaylistId, nil)
                } else {
                    let userInfo = ["NSLocalizedDescriptionKey": "PlaylistId is valid"]
                    let error = NSError(domain: "com.datalicious.news", code: 1002, userInfo: userInfo)
                    completionBlock(false, nil, error)
                }
            } else {
                completionBlock(false, nil, error)
            }
        }
    }
    
    private func getPlaylistItemForplaylistId(playlistId:String?, completionBlock:(Bool, GTLYouTubePlaylist?, NSError?)->()) {
        guard let playlistId = playlistId else {
            let userInfo = ["NSLocalizedDescriptionKey": "PlaylistId is valid"]
            let error = NSError(domain: "com.datalicious.news", code: 1002, userInfo: userInfo)
            completionBlock(false, nil, error)
            return
        }
        let playlistURLString = "https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=\(playlistId)&key=\(googleAPIKey)"
        let playlistURL = NSURL(string: playlistURLString)
        dispatch_async(dispatch_get_main_queue()) {[unowned self] in
            self.gtlServiceYouTube.fetchObjectWithURL(playlistURL) { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self.newtworkQueue.addOperationWithBlock({
                    if error == nil {
                        if let listResponse = object as? GTLYouTubePlaylistListResponse {
                            if let items = listResponse.items() {
                                if items.count > 0 {
                                    if let playlist = items[0] as? GTLYouTubePlaylist {
                                        completionBlock(true, playlist, nil)
                                    } else {
                                        print("Not YouTubeChannel \(items[0])")
                                        let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                                        let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                                        completionBlock(false, nil, error)
                                    }
                                } else {
                                    print("YouTubeChannel count \(items.count)")
                                    completionBlock(true, nil, nil)
                                }
                            } else {
                                print("No items found")
                                completionBlock(true, nil, nil)
                            }
                        } else {
                            print("listResponse is not GTLYouTubeChannelListResponse")
                            let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                            let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                            completionBlock(false, nil, error)
                        }
                    } else {
                        print(error)
                        completionBlock(false, nil, error)
                    }
                })
            }
        }
    }
    
    private func getAllRelatedPlayListsOfDataliciousFromYouTube(completionBlock:(Bool, GTLYouTubeChannelContentDetailsRelatedPlaylists?, NSError?)->()) {
        getChannelIdOfDataliciousFromYouTube {[unowned self] (success:Bool, channelId:String?, error:NSError?) in
            if success {
                let channelId = channelId!
                let channelURLString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=\(channelId)&key=\(googleAPIKey)"
                let channelURL = NSURL(string: channelURLString)
                dispatch_async(dispatch_get_main_queue(), {
                    self.gtlServiceYouTube.fetchObjectWithURL(channelURL, completionHandler: { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                        self.newtworkQueue.addOperationWithBlock({
                            if error == nil {
                                if let listResponse = object as? GTLYouTubeChannelListResponse {
                                    if let items = listResponse.items() {
                                        if items.count > 0 {
                                            if let channel = items[0] as? GTLYouTubeChannel {
                                                completionBlock(true, channel.contentDetails.relatedPlaylists, nil)
                                            } else {
                                                print("Not YouTubeChannel \(items[0])")
                                                let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                                                let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                                                completionBlock(false, nil, error)
                                            }
                                        } else {
                                            print("YouTubeChannel count \(items.count)")
                                            completionBlock(true, nil, nil)
                                        }
                                    } else {
                                        print("No items found")
                                        completionBlock(true, nil, nil)
                                    }
                                } else {
                                    print("listResponse is not GTLYouTubeChannelListResponse")
                                    let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                                    let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                                    completionBlock(false, nil, error)
                                }
                            } else {
                                print(error)
                                completionBlock(false, nil, error)
                            }
                        })
                    })
                })
            } else {
                print("Unsuccessful")
                completionBlock(false, nil, error)
            }
        }
    }

    private func getChannelIdOfDataliciousFromYouTube(completionBlock:(Bool, String?, NSError?)->()) {
        let urlString = "https://www.googleapis.com/youtube/v3/channels?part=id&forUsername=datalicious&key=\(googleAPIKey)"
        let url = NSURL(string: urlString)
        dispatch_async(dispatch_get_main_queue()) {[unowned self] in
            self.gtlServiceYouTube.fetchObjectWithURL(url) { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self.newtworkQueue.addOperationWithBlock({
                    if error == nil {
                        if let listResponse = object as? GTLYouTubeChannelListResponse {
                            if let items = listResponse.items() {
                                if items.count > 0 {
                                    if let channel = items[0] as? GTLYouTubeChannel {
                                        completionBlock(true, channel.identifier, nil)
                                    } else {
                                        print("Not YouTubeChannel \(items[0])")
                                        let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                                        let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                                        completionBlock(false, nil, error)
                                    }
                                } else {
                                    print("YouTubeChannel count \(items.count)")
                                    completionBlock(true, nil, nil)
                                }
                            } else {
                                print("No items found")
                                completionBlock(true, nil, nil)
                            }
                        } else {
                            print("listResponse is not GTLYouTubeChannelListResponse")
                            let userInfo = ["NSLocalizedDescriptionKey": "Youtube response couldn't be parsed"]
                            let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                            completionBlock(false, nil, error)
                        }
                    } else {
                        print(error)
                        completionBlock(false, nil, error)
                    }
                })
            }
        }
    }
    
    
    // MARK: Contacts...
    func getContactDetailsFromDatalicicous(completionBlock: (Bool, NSError?)->()) {
        performAPICall("http://www.datalicious.com/contact/", method: nil, parameters: [:]) { (success:Bool, data:NSData?, error:NSError?) in
            if success {
                if let data = data {
                    let hppleParser = TFHpple(HTMLData: data)
                    let rootXElements = hppleParser.searchWithXPathQuery("/html/body/div/main/section[@class='addresses-section']/div/div/div")
                    let newsController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                    for contactElement in rootXElements {
                        if let contactElement = contactElement as? TFHppleElement {
                            var mapURL: String = ""
                            if contactElement.children.count > 7 {
                                if let element = contactElement.children[7] as? TFHppleElement {
                                    if let mapUrlString = element.attributes["href"] as? String {
                                        mapURL = mapUrlString
                                    }
                                }
                            }
                            var contactAlreadyExists = false
                            if mapURL.characters.count > 0 {
                                let predicate = NSPredicate(format: "mapURL=%@", mapURL)
                                contactAlreadyExists = newsController.checkIfObjectExistInDatabase("Contact", predicate: predicate)
                            }
                            if !contactAlreadyExists {
                                newsController.insertContactObject(contactElement, mapURLString: mapURL)
                            }
                        }
                    }
                    newsController.saveMoc()
                    completionBlock(true, nil)
                } else {
                    let userInfo = ["NSLocalizedDescriptionKey": "Data not found"]
                    let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                    completionBlock(false, error)
                }
            } else {
                completionBlock(false,error)
            }
        }
    }
    
    func performAPICall(urlString: String, method: String?, parameters: [String: AnyObject], withCompletionBlock completionBlock: (Bool, NSData?, NSError?)->()) {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let manager = NSURLSession(configuration: configuration)
        let request = NSURLRequest(URL: NSURL(string: urlString)!)
        let dataTask = manager.dataTaskWithRequest(request) { (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                if let data = data {
                    completionBlock(true, data, nil)
                } else {
                    print(response)
                    let userInfo = ["NSLocalizedDescriptionKey": "Data not found"]
                    let error = NSError(domain: "com.datalicious.news", code: 1001, userInfo: userInfo)
                    completionBlock(false, nil, error)
                }
            } else {
                print(error)
                completionBlock(false, nil, error)
            }
        }
        dataTask.resume()
    }
}

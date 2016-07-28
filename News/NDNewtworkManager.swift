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
import GoogleSignIn
import iOS_GTLYouTube

let googleAPIKey = ""

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
    func fetchDataLiciousBlogFeeds(completionBlock: (Bool)->()) {
        performAPICall("http://blog.datalicious.com/feed/", method: nil, parameters: [:], headers: [:]) { (success: Bool, data: NSData?) in
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
    
    // MARK: tweets from user account...
    func fetchTweets(completionBlock: (Bool, String?)->()) {
        searchTweets(["q":"from@datalicious"], completionBlock: { (success, tweets) in
            if let tweeetArray = tweets {
                var filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
                filePath = filePath + "/Tweets"
                let success = NSKeyedArchiver.archiveRootObject(tweeetArray, toFile: filePath)
                completionBlock(success, (success ? filePath : nil))
            } else {
                completionBlock(success, nil)
            }
        })
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
    
    
    // MARK: YouTube videos
    func getYoutubeDataliciousPlaylistIds(completionBlock: (Bool, [GTLYouTubePlaylist]?)->()) {
        getAllRelatedPlayListsOfDataliciousFromYouTube {[weak self] (success:Bool, relatedPlaylist:GTLYouTubeChannelContentDetailsRelatedPlaylists?) in
            if success {
                var count:Int = 0
                var playlists = [GTLYouTubePlaylist]()
                count = count + 1
                self?.newtworkQueue.addOperationWithBlock({
                    self?.getPlaylistItemForplaylistId(relatedPlaylist!.favorites, completionBlock: { (success:Bool, obtainedPlaylist:GTLYouTubePlaylist?) in
                        if success {
                            if let playlist = obtainedPlaylist {
                                playlists += [playlist]
                            }
                        }
                        count = count - 1
                    })
                })
                count = count + 1
                self?.newtworkQueue.addOperationWithBlock({
                    self?.getPlaylistItemForplaylistId(relatedPlaylist!.likes, completionBlock: { (success:Bool, obtainedPlaylist:GTLYouTubePlaylist?) in
                        if success {
                            if let playlist = obtainedPlaylist {
                                playlists += [playlist]
                            }
                        }
                        count = count - 1
                    })
                })
                count = count + 1
                self?.newtworkQueue.addOperationWithBlock({
                    self?.getPlaylistItemForplaylistId(relatedPlaylist!.uploads, completionBlock: { (success:Bool, obtainedPlaylist:GTLYouTubePlaylist?) in
                        if success {
                            if let playlist = obtainedPlaylist {
                                playlists += [playlist]
                            }
                        }
                        count = count - 1
                    })
                })
                while count != 0 {
                }
                completionBlock(true, playlists)
            } else {
                completionBlock(false, nil)
            }
        }
    }
    
    private func getPlaylistItemForplaylistId(playlistId:String?, completionBlock:(Bool, GTLYouTubePlaylist?)->()) {
        guard let playlistId = playlistId else {
            completionBlock(false, nil)
            return
        }
        let playlistURLString = "https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=\(playlistId)&key=\(googleAPIKey)"
        let playlistURL = NSURL(string: playlistURLString)
        dispatch_async(dispatch_get_main_queue()) {[weak self] in
            self?.gtlServiceYouTube.fetchObjectWithURL(playlistURL) { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self?.newtworkQueue.addOperationWithBlock({
                    if error == nil {
                        if let listResponse = object as? GTLYouTubePlaylistListResponse {
                            if let items = listResponse.items() {
                                if items.count > 0 {
                                    if let playlist = items[0] as? GTLYouTubePlaylist {
                                        completionBlock(true, playlist)
                                    } else {
                                        print("Not YouTubeChannel \(items[0])")
                                        completionBlock(false, nil)
                                    }
                                } else {
                                    print("YouTubeChannel count \(items.count)")
                                    completionBlock(false, nil)
                                }
                            } else {
                                print("No items found")
                                completionBlock(false, nil)
                            }
                        } else {
                            print("listResponse is not GTLYouTubeChannelListResponse")
                            completionBlock(false, nil)
                        }
                    } else {
                        print(error)
                        completionBlock(false, nil)
                    }
                })
            }
        }
    }
    
    private func getAllRelatedPlayListsOfDataliciousFromYouTube(completionBlock:(Bool, GTLYouTubeChannelContentDetailsRelatedPlaylists?)->()) {
        getChannelIdOfDataliciousFromYouTube {[weak self] (success:Bool, channelId:String?) in
            if success {
                let channelId = channelId!
                let channelURLString = "https://www.googleapis.com/youtube/v3/channels?part=contentDetails&id=\(channelId)&key=\(googleAPIKey)"
                let channelURL = NSURL(string: channelURLString)
                dispatch_async(dispatch_get_main_queue(), {
                    self?.gtlServiceYouTube.fetchObjectWithURL(channelURL, completionHandler: { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                        self?.newtworkQueue.addOperationWithBlock({
                            if error == nil {
                                if let listResponse = object as? GTLYouTubeChannelListResponse {
                                    if let items = listResponse.items() {
                                        if items.count > 0 {
                                            if let channel = items[0] as? GTLYouTubeChannel {
                                                completionBlock(true, channel.contentDetails.relatedPlaylists)
                                            } else {
                                                print("Not YouTubeChannel \(items[0])")
                                                completionBlock(false, nil)
                                            }
                                        } else {
                                            print("YouTubeChannel count \(items.count)")
                                            completionBlock(false, nil)
                                        }
                                    } else {
                                        print("No items found")
                                        completionBlock(false, nil)
                                    }
                                } else {
                                    print("listResponse is not GTLYouTubeChannelListResponse")
                                    completionBlock(false, nil)
                                }
                            } else {
                                print(error)
                                completionBlock(false, nil)
                            }
                        })
                    })
                })
            } else {
                print("Unsuccessful")
                completionBlock(false, nil)
            }
        }
    }

    private func getChannelIdOfDataliciousFromYouTube(completionBlock:(Bool, String?)->()) {
        let urlString = "https://www.googleapis.com/youtube/v3/channels?part=id&forUsername=datalicious&key=\(googleAPIKey)"
        let url = NSURL(string: urlString)
        dispatch_async(dispatch_get_main_queue()) {[weak self] in
            self?.gtlServiceYouTube.fetchObjectWithURL(url) { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self?.newtworkQueue.addOperationWithBlock({
                    if error == nil {
                        if let listResponse = object as? GTLYouTubeChannelListResponse {
                            if let items = listResponse.items() {
                                if items.count > 0 {
                                    if let channel = items[0] as? GTLYouTubeChannel {
                                        completionBlock(true, channel.identifier)
                                    } else {
                                        print("Not YouTubeChannel \(items[0])")
                                        completionBlock(false, nil)
                                    }
                                } else {
                                    print("YouTubeChannel count \(items.count)")
                                    completionBlock(false, nil)
                                }
                            } else {
                                print("No items found")
                                completionBlock(false, nil)
                            }
                        } else {
                            print("listResponse is not GTLYouTubeChannelListResponse")
                            completionBlock(false, nil)
                        }
                    } else {
                        print(error)
                        completionBlock(false, nil)
                    }
                })
            }
        }
    }
    
    
    // MARK: Contacts...
    func getContactDetailsFromDatalicicous(completionBlock: (Bool)->()) {
        performAPICall("http://www.datalicious.com/contact/", method: nil, parameters: [:], headers: [:]) { (success:Bool, data:NSData?) in
            
        }
    }
    
    func performAPICall(urlString: String, method: String?, parameters: [String: AnyObject], headers:[String: String], withCompletionBlock completionBlock: (Bool, NSData?)->()) {
        Alamofire.request(.GET, urlString, parameters: parameters, headers:headers)
            .response { (request, response, data, error) in
                if error == nil {
                    completionBlock(true, data)
                } else {
                    completionBlock(false, nil)
                }
        }
    }
}

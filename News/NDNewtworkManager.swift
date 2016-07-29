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
                    let blogId = blogItemDictionary["guid"] as! String
                    let predicate = NSPredicate(format: "blogId=%@", blogId)
                    if newsItemController.checkIfObjectExistInDatabase("BlogItem", predicate:predicate) == false {
                        newsItemController.insertBlogObject(blogItemDictionary)
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
    func getYouTubeDataliciousVideos(completionBlock:(Bool)->()) {
        getYoutubeDataliciousUploadPlaylistId {[unowned self] (success:Bool, playlistid:String?) in
            if success {
                if let id = playlistid {
                    self.getYouTubeVideosForPlaylistItemId(id, pageToken: nil, completionBlock: { (success:Bool) in
                        
                    })
                } else {
                    completionBlock(false)
                }
            }
        }
    }
    
    func getYouTubeVideosForPlaylistItemId(playlistItemId:String, pageToken:String?, completionBlock:(Bool)->()) {
        var playlistItemURLString = "https://www.googleapis.com/youtube/v3/playlistItems?part=snippet%2CcontentDetails&playlistId=\(playlistItemId)&"
        playlistItemURLString = playlistItemURLString + (pageToken != nil ? "pageToken=\(pageToken!)&key=\(googleAPIKey)" : "key=\(googleAPIKey)")
        let playlistItemURL = NSURL(string: playlistItemURLString)
        dispatch_async(dispatch_get_main_queue()) {[unowned self] in
            self.gtlServiceYouTube.fetchObjectWithURL(playlistItemURL, completionHandler: { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self.newtworkQueue.addOperationWithBlock({
                    if error == nil {
                        if let listResponse = object as? GTLYouTubePlaylistItemListResponse {
                            if let items = listResponse.items() as? Array<GTLYouTubePlaylistItem> {
                                let newsItemController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                                for playlist in items {
                                    let videoId = playlist.snippet.resourceId.videoId
                                    let predicate = NSPredicate(format: "videoId = %@", videoId)
                                    if !newsItemController.checkIfObjectExistInDatabase("YouTubeVideo", predicate: predicate) {
                                        newsItemController.insertYouTubeVideoObject(playlist.snippet)
                                    }
                                }
                                newsItemController.saveMoc()
                                if listResponse.nextPageToken != nil {
                                    self.getYouTubeVideosForPlaylistItemId(playlistItemId, pageToken: listResponse.nextPageToken, completionBlock: { (success:Bool) in
                                        completionBlock(success)
                                    })
                                } else {
                                    completionBlock(true)
                                }
                            } else {
                                print("No items found")
                                completionBlock(false)
                            }
                        } else {
                            print("listResponse is not GTLYouTubeChannelListResponse")
                            completionBlock(false)
                        }
                    } else {
                        print(error)
                        completionBlock(false)
                    }
                })
            })
        }
    }
    
    private func getYoutubeDataliciousUploadPlaylistId(completionBlock: (Bool, String?)->()) {
        getAllRelatedPlayListsOfDataliciousFromYouTube {[unowned self] (success:Bool, relatedPlaylist:GTLYouTubeChannelContentDetailsRelatedPlaylists?) in
            if success {
                var count:Int = 1
                var uploadPlaylist: GTLYouTubePlaylist! = nil
                self.newtworkQueue.addOperationWithBlock({
                    self.getPlaylistItemForplaylistId(relatedPlaylist!.uploads, completionBlock: { (success:Bool, obtainedPlaylist:GTLYouTubePlaylist?) in
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
                    completionBlock(true, uploadPlaylistId)
                } else {
                    completionBlock(false, nil)
                }
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
        dispatch_async(dispatch_get_main_queue()) {[unowned self] in
            self.gtlServiceYouTube.fetchObjectWithURL(playlistURL) { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self.newtworkQueue.addOperationWithBlock({
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
        getChannelIdOfDataliciousFromYouTube {[unowned self] (success:Bool, channelId:String?) in
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
        dispatch_async(dispatch_get_main_queue()) {[unowned self] in
            self.gtlServiceYouTube.fetchObjectWithURL(url) { (ticket:GTLServiceTicket!, object:AnyObject!, error:NSError!) in
                self.newtworkQueue.addOperationWithBlock({
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

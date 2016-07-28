//
//  NDYouTubeViewController.swift
//  News
//
//  Created by Sachin Vas on 7/25/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import GoogleSignIn
import iOS_GTLYouTube

let youTubeKeyChain = "YouTubeKeyChain"
let youTubeClientId = ""
let youTubeScopes = [
                     "https://www.googleapis.com/auth/youtube",
                     "https://www.googleapis.com/auth/youtube.readonly",
                     "https://www.googleapis.com/auth/youtubepartner",
                     "https://www.googleapis.com/auth/youtubepartner-channel-audit",
                     "https://www.googleapis.com/auth/youtube.upload"
                    ]

class NDYouTubeViewController: UITableViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    private var playlists:[GTLYouTubePlaylist]!
    private var videos:[GTLYouTubeVideo]!
    private var isShowingPlaylists: Bool = true
    private var networkQueue: NSOperationQueue {
        let queue = NSOperationQueue()
        queue.qualityOfService = .Utility
        return queue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        GIDSignIn.sharedInstance().scopes = youTubeScopes
        GIDSignIn.sharedInstance().clientID = youTubeClientId
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().signIn()
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        let urlString = "https://www.googleapis.com/oauth2/v1/tokeninfo?access_token=\(user.authentication.accessToken)"
        NDNetworkManager.sharedManager.performAPICall(urlString, method: nil, parameters: [:], headers: [:]) {[weak self] (success:Bool, data:NSData?) in
            if success {
                self?.fetchYouTubeVideos()
                if let responseData = data {
                    do {
                        let jsonObject = try NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions(rawValue:0))
                        print(jsonObject)
                    } catch let error {
                        print(error)
                    }
                }
            }
        }
    }
    
    func signIn(signIn: GIDSignIn!, didDisconnectWithUser user: GIDGoogleUser!, withError error: NSError!) {
        
    }
    
    func signInWillDispatch(signIn: GIDSignIn!, error: NSError!) {
        
    }
    
    func signIn(signIn: GIDSignIn!, presentViewController viewController: UIViewController!) {
        let googleSignInNavController = UINavigationController(rootViewController: viewController)
        navigationController?.presentViewController(googleSignInNavController, animated: true, completion: nil)
    }
    
    func signIn(signIn: GIDSignIn!, dismissViewController viewController: UIViewController!) {
        viewController.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func fetchYouTubeVideos() {
        networkQueue.addOperationWithBlock {
            NDNetworkManager.sharedManager.getYoutubeDataliciousPlaylistIds {[weak self] (sucess:Bool, playlists:[GTLYouTubePlaylist]?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self?.playlists = playlists
                    self?.tableView.reloadData()
                })
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (isShowingPlaylists ? self.playlists.count : self.videos.count)
    }
}


//
//  NDYouTubeViewController.swift
//  News
//
//  Created by Sachin Vas on 7/25/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import GTMOAuth2

let youTubeKeyChain = "YouTubeKeyChain"
let youTubeClientId = "1062429885959-rj7cbqmrtqh8j2uc0lujlditp9qg6p94.apps.googleusercontent.com"
let youTubeClientSecret = ""
let youTubeLoginURL = "https://www.googleapis.com/auth/plus.me"

class NDYouTubeViewController: UITableViewController {
    
    var authentication: GTMOAuth2Authentication!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let auth = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(youTubeKeyChain, clientID: youTubeClientId, clientSecret: youTubeClientSecret)
        if auth.canAuthorize {
            do {
                try GTMOAuth2ViewControllerTouch.authorizeFromKeychainForName(youTubeKeyChain, authentication: auth)
    
                authentication = auth
                fetchYouTubeVideos()
            } catch let error {
                print(error)
            }
        } else {
            let googleAuthViewController = GTMOAuth2ViewControllerTouch(scope: youTubeLoginURL, clientID: youTubeClientId, clientSecret: youTubeClientSecret, keychainItemName: youTubeKeyChain) {[weak self] (viewController: GTMOAuth2ViewControllerTouch!, authentication: GTMOAuth2Authentication!, error: NSError!) in
                GTMOAuth2ViewControllerTouch.saveParamsToKeychainForName(youTubeKeyChain, authentication: authentication)
                viewController.dismissViewControllerAnimated(true, completion: nil)
                self?.authentication = authentication
                self?.fetchYouTubeVideos()
            }
            navigationController?.presentViewController(googleAuthViewController, animated: true, completion: nil)
        }
    }
    
    func fetchYouTubeVideos() {
        NDNetworkManager.sharedManager.getYoutubeDataliciousVideos(authentication) { (sucess: Bool) in
            
        }
    }
}


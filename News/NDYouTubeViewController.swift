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
import MBProgressHUD
import CoreData
import AVKit
import AVFoundation
import XCDYouTubeKit

let youTubeKeyChain = "YouTubeKeyChain"
let youTubeClientId = "1048490923287-9dh44tgkdoskp5t001ppqqp7ac92prfp.apps.googleusercontent.com"
let youTubeScopes = [
                     "https://www.googleapis.com/auth/youtube",
                     "https://www.googleapis.com/auth/youtube.readonly",
                     "https://www.googleapis.com/auth/youtubepartner",
                     "https://www.googleapis.com/auth/youtubepartner-channel-audit",
                     "https://www.googleapis.com/auth/youtube.upload"
                    ]

class NDYouTubeViewController: UITableViewController, GIDSignInDelegate, GIDSignInUIDelegate, NSFetchedResultsControllerDelegate {
    
    lazy private var fetchedResultsController: NSFetchedResultsController! = {
        let fetchRequest = NSFetchRequest(entityName: "YouTubeVideo")
        let sortDescriptor = NSSortDescriptor(key: "position", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NDCoreDataManager.sharedManager.mainQueueMOC, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultController.delegate = self
        return fetchResultController
    }()

    var activityView: MBProgressHUD!
    private var networkQueue: NSOperationQueue {
        let queue = NSOperationQueue()
        queue.qualityOfService = .Utility
        return queue
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let blogItemCell = UINib(nibName: "NDTableViewCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(blogItemCell, forCellReuseIdentifier: "YouTubeVideoCell")
        
        activityView = MBProgressHUD.showHUDAddedTo(self.tableView, animated: true)
        activityView.label.text = "YouTube"
        activityView.detailsLabel.text = "Signing In..."
        GIDSignIn.sharedInstance().scopes = youTubeScopes
        GIDSignIn.sharedInstance().clientID = youTubeClientId
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        if GIDSignIn.sharedInstance().hasAuthInKeychain() {
            GIDSignIn.sharedInstance().signInSilently()
        } else {
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print(error)
        }
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError!) {
        fetchYouTubeVideos()
        activityView.detailsLabel.text = "Fetching Videos..."
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
            NDNetworkManager.sharedManager.getYouTubeDataliciousVideos {[weak self] (sucess:Bool, error: NSError?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self?.activityView.hidden = true
                    if sucess {
                        self?.performFetch()
                        self?.tableView.reloadData()
                    } else if let error = error {
                        let alertController = UIAlertController(title: "Error Occurred", message: error.localizedDescription, preferredStyle: .Alert)
                        let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action:UIAlertAction) in
                            alertController.dismissViewControllerAnimated(true, completion: nil)
                        })
                        alertController.addAction(action)
                        self?.navigationController?.presentViewController(alertController, animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numOfRowsInSection = 0
        if let count = self.fetchedResultsController.fetchedObjects?.count {
            numOfRowsInSection = count
        }
        return numOfRowsInSection
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tableViewCell = tableView.dequeueReusableCellWithIdentifier("YouTubeVideoCell") as? NDTableViewCell
        if tableViewCell == nil {
            tableViewCell = UITableViewCell(style: .Default, reuseIdentifier: "YouTubeVideoCell") as? NDTableViewCell
        }
        tableViewCell?.accessoryType = .DisclosureIndicator
        return tableViewCell!
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let youTubeVideoCell = cell as? NDTableViewCell {
            let youTubeVideo = self.fetchedResultsController.fetchedObjects![indexPath.row] as! YouTubeVideo
            youTubeVideoCell.populateCellData(youTubeVideo.publishedAt!, titleText: youTubeVideo.title!, information: (text:youTubeVideo.videoDescription!, isHTML:false), avatarImagePath: youTubeVideo.thumbnailPath, iconGroup: .YouTube)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        let youTubeVideo = self.fetchedResultsController.fetchedObjects![indexPath.row] as! YouTubeVideo
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {[weak self] in
            XCDYouTubeClient.defaultClient().getVideoWithIdentifier(youTubeVideo.videoId!) { (video:XCDYouTubeVideo?, error:NSError?) in
                dispatch_async(dispatch_get_main_queue(), {
                    if error == nil {
                        if let xcYouTubeVideo = video {
                            let playerController = AVPlayerViewController()
                            var url: NSURL? = nil
                            for preferedQuality in [XCDYouTubeVideoQuality.Small240, XCDYouTubeVideoQuality.Medium360] {
                                if (xcYouTubeVideo.streamURLs[preferedQuality.rawValue as NSObject] != nil) {
                                    url = xcYouTubeVideo.streamURLs[preferedQuality.rawValue as NSObject]!
                                }
                            }
                            playerController.player = AVPlayer(URL: url!)
                            self?.navigationController?.presentViewController(playerController, animated: true, completion: nil)
                        } else {
                            print("no Video found")
                        }
                    } else {
                        print(error)
                    }
                })
            }
        }
    }
}


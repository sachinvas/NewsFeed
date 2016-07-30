//
//  NDTwitterViewController.swift
//  News
//
//  Created by Sachin Vas on 7/25/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import TwitterKit
import MBProgressHUD


class NDTwitterViewController: UITableViewController {
    
    var tweets: [TWTRTweet]! = []
    var session: TWTRSession!
    var activityView: MBProgressHUD!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        activityView = MBProgressHUD.showHUDAddedTo(self.tableView, animated: true)
        activityView.label.text = "Twitter"
        activityView.detailsLabel.text = "Signing In..."
        
        if let session: TWTRSession = Twitter.sharedInstance().sessionStore.existingUserSessions().count > 0 ? Twitter.sharedInstance().sessionStore.existingUserSessions()[0] as? TWTRSession : nil {
            let error:NSError = NSError(domain: "", code: -999, userInfo: nil)
            let isExpired = Twitter.sharedInstance().sessionStore.isExpiredSession(session, error: error)
            if !isExpired {
                self.session = session
                fetchTweets()
            } else {
                Twitter.sharedInstance().sessionStore.refreshSessionClass(TWTRSession.self, sessionID: session.userID, completion: {[weak self] (session: AnyObject?, error: NSError?) in
                    if error == nil {
                        if let trtwSession = session as? TWTRSession {
                            self?.session = trtwSession
                            self?.fetchTweets()
                        }
                    }
                })
            }
        } else {
            Twitter.sharedInstance().logInWithCompletion {[weak self] (session: TWTRSession?, error: NSError?) in
                if error == nil {
                    if let trtwSession = session {
                        self?.session = trtwSession
                        self?.fetchTweets()
                    }
                }
            }
        }
    }
    
    func fetchTweets() {
        activityView.detailsLabel.text = "Fetching Tweets..."
        NDNetworkManager.sharedManager.fetchTweets {[weak self] (success: Bool, filePath: String?) in
            dispatch_async(dispatch_get_main_queue(), {
                self?.activityView.hidden = true
                self?.activityView.hideAnimated(true)
                if success {
                    if let tweetArray = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath!) as? Array<TWTRTweet> {
                        self?.tweets = tweetArray
                        self?.tableView.reloadData()
                    }
                }
            })
        }
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numOfRows = 0
        if activityView.hidden {
            numOfRows = self.tweets.count
        }
        return numOfRows
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let tweet = self.tweets[indexPath.row]
        return TWTRTweetTableViewCell.heightForTweet(tweet, style: .Regular, width: tableView.frame.size.height, showingActions: false) - 180
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tableViewCell = tableView.dequeueReusableCellWithIdentifier("TweetCell") as? TWTRTweetTableViewCell
        if tableViewCell == nil {
            tableViewCell = TWTRTweetTableViewCell(style: .Default, reuseIdentifier: "TweetCell")
        }
        let tweet = self.tweets[indexPath.row]
        tableViewCell!.configureWithTweet(tweet)
        return tableViewCell!
    }
}
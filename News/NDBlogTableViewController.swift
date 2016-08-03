//
//  NDBlogTableViewController.swift
//  News
//
//  Created by Sachin Vas on 7/15/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MBProgressHUD

class NDBlogTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    private var loadingSpinner: MBProgressHUD!
    
    lazy var fetchedResultsController: NSFetchedResultsController! = {
        let fetchRequest = NSFetchRequest(entityName: "BlogItem")
        let sortDescriptor = NSSortDescriptor(key: "publicationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NDCoreDataManager.sharedManager.mainQueueMOC, sectionNameKeyPath: nil, cacheName: nil)
        fetchResultController.delegate = self
        return fetchResultController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let blogItemCell = UINib(nibName: "NDTableViewCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(blogItemCell, forCellReuseIdentifier: "BlogItemCell")
        
        loadingSpinner = MBProgressHUD.showHUDAddedTo(self.tableView, animated: true)
        loadingSpinner.label.text = "Fetching Blogs..."
        performFetch()
        NDNetworkManager.sharedManager.fetchDataLiciousBlogFeeds({[weak self](success:Bool, error:NSError?) -> () in
            dispatch_async(dispatch_get_main_queue(), {
                self?.loadingSpinner.hideAnimated(true)
                if success {
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
        })
    }
    
    func performFetch() {
        do {
            try fetchedResultsController.performFetch()
        } catch let error {
            print(error)
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
        var tableViewCell = tableView.dequeueReusableCellWithIdentifier("BlogItemCell") as? NDTableViewCell
        if tableViewCell == nil {
            tableViewCell = UITableViewCell(style: .Default, reuseIdentifier: "BlogItemCell") as? NDTableViewCell
        }
        tableViewCell?.accessoryType = .DisclosureIndicator
        return tableViewCell!
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if let blogItemCell = cell as? NDTableViewCell {
            let blogItem = self.fetchedResultsController.fetchedObjects![indexPath.row] as! BlogItem
            blogItemCell.populateCellData(blogItem.publicationDate!, titleText: blogItem.title!, information: (text:blogItem.blogDescription!, isHTML:true), avatarImagePath: nil, iconGroup: nil)
        }
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let blogItem = self.fetchedResultsController.fetchedObjects?[indexPath.row] as? BlogItem where blogItem.linkURL != nil {
            let safariViewController = NDSafariViewController()
            let url = NSURL(string: blogItem.linkURL!)
            safariViewController.request = NSURLRequest(URL: url!)
            safariViewController.title = blogItem.title
            safariViewController.showNavigationOnPush = true
            navigationController?.pushViewController(safariViewController, animated: true)
        }
    }
}

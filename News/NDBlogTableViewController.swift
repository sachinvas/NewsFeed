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
        fetchRequest.fetchLimit = 10
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
        NDNetworkManager.sharedManager.fetchDataLiciousBlogFeeds({[weak self](success:Bool) -> () in
            dispatch_async(dispatch_get_main_queue(), {
                if success {
                    self?.performFetch()
                    self?.tableView.reloadData()
                    self?.loadingSpinner.hideAnimated(true)
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
            blogItemCell.populateCellData(blogItem.publicationDate!, titleText: blogItem.title!, information: (text:blogItem.blogDescription!, isHTML:true), avatarImagePath: nil)
        }
    }
}

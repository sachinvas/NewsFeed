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

class NDBlogTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    private var loadingSpinner: UIActivityIndicatorView!
    
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
        
        let blogItemCell = UINib(nibName: "NDBlogItemTableViewCell", bundle: NSBundle.mainBundle())
        tableView.registerNib(blogItemCell, forCellReuseIdentifier: "BlogItemCell")

        loadingSpinner = UIActivityIndicatorView()
        loadingSpinner.activityIndicatorViewStyle = .Gray
        let x = tableView.frame.size.width/2 - 10
        let y = tableView.frame.size.height/2 - 10
        loadingSpinner.frame = CGRectMake(x, y, 20, 20)
        loadingSpinner.hidesWhenStopped = true
        tableView.addSubview(loadingSpinner)
        
        performFetch()
        loadingSpinner.startAnimating()
        NDNetworkManager.sharedManager.fetchDataLiciousBlogFeeds({[weak self](success:Bool) -> () in
            dispatch_async(dispatch_get_main_queue(), {
                self?.loadingSpinner.stopAnimating()
                if success {
                    self?.performFetch()
                    self?.tableView.reloadData()
                    
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
        return 175
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numOfRowsInSection = 0
        if let count = self.fetchedResultsController.fetchedObjects?.count {
            numOfRowsInSection = count
        }
        return numOfRowsInSection
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tableViewCell = tableView.dequeueReusableCellWithIdentifier("BlogItemCell") as? NDBlogItemTableViewCell
        if tableViewCell == nil {
            tableViewCell = UITableViewCell(style: .Default, reuseIdentifier: "BlogItemCell") as? NDBlogItemTableViewCell
        }
        let blogItem = self.fetchedResultsController.fetchedObjects![indexPath.row] as! BlogItem
        tableViewCell!.dateLabel.text = NDUtility.utility.newsDateDisplayFormatter.stringFromDate(blogItem.publicationDate!)
        tableViewCell!.titleLabel.text = blogItem.title
        dispatch_async(dispatch_get_main_queue()) {
            do {
                tableViewCell!.descriptionTextView.attributedText = try NSAttributedString(data: blogItem.blogDescription!.dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                    NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes: nil)
            } catch let error {
                print(error)
            }
        }
        tableViewCell?.accessoryType = .DisclosureIndicator
        return tableViewCell!
    }
    
}

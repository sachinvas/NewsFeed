//
//  NDPinterestPinViewController.swift
//  News
//
//  Created by Sachin Vas on 8/1/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import PinterestSDK
import CoreData
import MBProgressHUD

class NDPinterestPinViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    var boardId:String!
    var responseObject: PDKResponseObject = PDKResponseObject()
    var tableFooterSpinner:MBProgressHUD!
    var isFetchingNext = false
        
    lazy var fetchedResultsController: NSFetchedResultsController! = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let predicate = NSPredicate(format: "boardId=%@", self.boardId)
        let sortDescriptor = NSSortDescriptor(key: "pinId", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = predicate
        let fetchResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: NDCoreDataManager.sharedManager.mainQueueMOC, sectionNameKeyPath: nil, cacheName: nil)
        return fetchResultController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.backItem?.title = "Back"
        
        let nib = UINib(nibName: "NDTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "PinterestPin")
        
        performFetch()
         
        PDKClient.sharedInstance().getBoardPins(boardId, fields: ["id", "image", "note", "link", "created_at"], withSuccess: {[weak self] (responseObject:PDKResponseObject!) in
            self?.responseObject = responseObject
            self?.addObjectToDatabase()
        }) { (error:NSError!) in
            print(error)
        }
    }
    
    func addObjectToDatabase() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {[weak self] in
            if let pins = self?.responseObject.pins() as? Array<PDKPin> {
                let newsController = NDNewsItemController(moc: NDCoreDataManager.sharedManager.backgroundMOC)
                for pin in pins {
                    let predicate = NSPredicate(format: "pinId=%@ AND boardId=%@", pin.identifier, (self?.boardId)!)
                    let objectExists = newsController.checkIfObjectExistInDatabase("Pin", predicate: predicate)
                    if !objectExists {
                        newsController.insertPinObject(pin, boardId: (self?.boardId)!)
                    }
                }
                newsController.saveMoc()
                self?.isFetchingNext = false
            } else {
                print("NO pins found");
            }
        }
    }
    
    func performFetch() {
        do {
            if fetchedResultsController.delegate == nil {
                fetchedResultsController.delegate = self
            }
            try fetchedResultsController.performFetch()
        } catch let error {
            print(error)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController() {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numOfRows = 0
        if let count = self.fetchedResultsController.fetchedObjects?.count {
            numOfRows = count
        }
        return numOfRows
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("PinterestPin", forIndexPath: indexPath) as? NDTableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "PinterestPin") as? NDTableViewCell
        }
        
        if let pin = self.fetchedResultsController.fetchedObjects?[indexPath.row] as? Pin {
            cell?.populateCellData(pin.creationTime!, titleText: pin.name!, information: (text: pin.descriptionText ?? "", isHTML: false), avatarImagePath: pin.imageURL, iconGroup: .Pinterest)
        }
        cell?.accessoryType = .DisclosureIndicator
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows {
            if indexPathsForVisibleRows.count > 0 && indexPathsForVisibleRows[indexPathsForVisibleRows.count - 1].row > ((self.fetchedResultsController.fetchedObjects?.count)! - 2) {
                if !isFetchingNext {
                    isFetchingNext = true
                    if responseObject.hasNext() {
                        responseObject.loadNextWithSuccess({[weak self] (responseObject:PDKResponseObject!) in
                            self?.addObjectToDatabase()
                            }, andFailure: {[weak self] (error:NSError!) in
                                print(error)
                                self?.isFetchingNext = false
                        })
                    }
                }
            }
        }
        return nil
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let pin = self.fetchedResultsController.fetchedObjects?[indexPath.row] as? Pin {
            let safariViewController = NDSafariViewController()
            let url = NSURL(string: pin.link!)
            safariViewController.request = NSURLRequest(URL: url!)
            safariViewController.title = pin.name
            safariViewController.showNavigationOnPush = true
            navigationController?.pushViewController(safariViewController, animated: true)
        }
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch (type) {
        case .Insert:
            if let indexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Delete:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            break;
        case .Update:
            break;
        case .Move:
            if let indexPath = indexPath {
                tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
            }
            
            if let newIndexPath = newIndexPath {
                tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: .Fade)
            }
            break;
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableView.endUpdates()
    }
}

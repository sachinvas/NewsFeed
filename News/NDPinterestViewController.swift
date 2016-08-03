//
//  NDPinterestViewController.swift
//  News
//
//  Created by Sachin Vas on 7/25/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import PinterestSDK
import MBProgressHUD

class NDPinterestViewController: UITableViewController {
    
    var activityView:MBProgressHUD!
    var boards:Array<PDKBoard>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nib = UINib(nibName: "NDTableViewCell", bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: "PinterestBoard")
        activityView = MBProgressHUD.showHUDAddedTo(tableView, animated: true)
        activityView.label.text = "Pintereset"
        activityView.detailsLabel.text = "Logging In..."
        
        if PDKClient.sharedInstance().oauthToken != nil {
            PDKClient.sharedInstance().silentlyAuthenticateWithSuccess({[weak self] (success:PDKResponseObject!) in
                self?.activityView.hideAnimated(true)
                self?.fetchAllBoardsOfAuthenticatedUser()
                }, andFailure: {[weak self] (error:NSError!) in
                    print(error)
                    self?.activityView.hideAnimated(true)
            })
        } else {
            let permissions = [
                                PDKClientReadPublicPermissions,
                                PDKClientWritePublicPermissions,
                                PDKClientReadRelationshipsPermissions,
                                PDKClientWriteRelationshipsPermissions
                              ]
            PDKClient.sharedInstance().authenticateWithPermissions(permissions, withSuccess: {[weak self] (success:PDKResponseObject!) in
                self?.activityView.hideAnimated(true)
                self?.fetchAllBoardsOfAuthenticatedUser()
                }, andFailure: {[weak self] (error:NSError!) in
                    print(error)
                    self?.activityView.hideAnimated(true)
            })
        }
    }
    
    func fetchAllBoardsOfAuthenticatedUser() {
        activityView.detailsLabel.text = "Fetching Boards..."
        activityView.showAnimated(true)
        PDKClient.sharedInstance().getAuthorizedUserFollowedBoardsWithFields(["id", "image", "description", "name", "privacy"], success: {[weak self] (responseObject:PDKResponseObject!) in
            if let boards = responseObject.boards() as? Array<PDKBoard> {
                self?.boards = boards
                self?.tableView.reloadData()
            }
            self?.activityView.hideAnimated(true)
        }) {[weak self] (error:NSError!) in
            self?.activityView.hideAnimated(true)
                print(error)
        }
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numOfRows = 0
        if let boards = self.boards {
            numOfRows = boards.count
        }
        return numOfRows
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var tableViewCell = tableView.dequeueReusableCellWithIdentifier("PinterestBoard") as? NDTableViewCell
        if tableViewCell == nil {
            tableViewCell = UITableViewCell(style: .Default, reuseIdentifier: "PinterestBoard") as? NDTableViewCell
        }
        if let board = self.boards?[indexPath.row] {
            tableViewCell?.accessoryType = .DisclosureIndicator
            tableViewCell?.populateCellData(board.creationTime, titleText: board.name, information: (text: board.descriptionText, isHTML: false), avatarImagePath: board.smallestImage().url.absoluteString, iconGroup: .Pinterest)
        }
        return tableViewCell!
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if let board = self.boards?[indexPath.row] where board.identifier != nil {
            let pinsViewController = NDPinterestPinViewController(style: .Grouped)
            pinsViewController.boardId = board.identifier
            pinsViewController.title = board.name
            navigationController?.pushViewController(pinsViewController, animated: true)
        }
    }
}

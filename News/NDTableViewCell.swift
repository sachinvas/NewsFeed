//
//  NDTableViewCell.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import UIKit

class NDTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var informationLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var dateLabelLeadingConstraint: NSLayoutConstraint!
    
    func populateCellData(dateText: NSDate, titleText: String, information: (text: String, isHTML:Bool), avatarImagePath: String?) {
        dateLabel.text = NDUtility.utility.newsDateDisplayFormatter.stringFromDate(dateText)
        titleLabel.text = titleText
        if information.isHTML {
            dispatch_async(dispatch_get_main_queue(), {[weak self] in
                do {
                    let text = try NSAttributedString(data: information.text.dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                        NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes: nil)
                    self?.informationLabel.attributedText = text
                } catch let error {
                    print(error)
                    self?.informationLabel.text = information.text
                }
                })
        } else {
            informationLabel.text = information.text
        }
        if let avatarImagePath = avatarImagePath {
            NDNetworkManager.sharedManager.performAPICall(avatarImagePath, method: nil, parameters: [:], headers: [:], withCompletionBlock: {[weak self] (success:Bool, data:NSData?) in
                dispatch_async(dispatch_get_main_queue(), {
                    if success {
                        if let data = data {
                            self?.avatarImageView.image = UIImage(data: data)
                            return
                        }
                    }
                    self?.avatarImageView.image = UIImage(named: "AppIcon80x80")
                })
                })
        } else {
            dateLabelLeadingConstraint.constant = 0.0
            if avatarImageView != nil {
                avatarImageView.removeFromSuperview()
            }
        }
    }
}

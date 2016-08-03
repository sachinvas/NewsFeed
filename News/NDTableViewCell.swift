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
    var imagePath: String!
    var imageDownloadOperation: NDImageDownloaderOperation!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        if imagePath != nil {
            imageDownloadOperation.cancel()
        }
    }
    
    func populateCellData(dateText: NSDate, titleText: String, information: (text: String, isHTML:Bool), avatarImagePath: String?, iconGroup: IconGroup?) {
        dateLabel.text = NDUtility.utility.newsDateDisplayFormatter.stringFromDate(dateText)
        titleLabel.text = titleText
        if information.isHTML {
            dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0), {[weak self] in
                autoreleasepool({
                    var text:NSAttributedString!
                    do {
                        text = try NSAttributedString(data: information.text.dataUsingEncoding(NSUTF8StringEncoding)!, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding], documentAttributes: nil)
                        if  self?.informationLabel.attributedText != nil {
                            self?.informationLabel.attributedText = nil
                        }
                    } catch let error {
                        print(error)
                    }
                    dispatch_async(dispatch_get_main_queue(), {[weak self] in
                        if text != nil {
                            self?.informationLabel.attributedText = text
                            text = nil
                        } else {
                            self?.informationLabel.text = information.text
                        }
                        })
                })
                })
        } else if information.text.characters.count > 0 {
            dispatch_async(dispatch_get_main_queue(), {[weak self] in
                let text = NSAttributedString(string: information.text, attributes: nil)
                self?.informationLabel.attributedText = text
                self?.informationLabel.sizeToFit()
                })
        }
        if let avatarImagePath = avatarImagePath {
             if !setImageWithAvatarImagePath(avatarImagePath, iconGroup: iconGroup) {
                self.avatarImageView.image = UIImage(named: "AppIcon40x40")
                imagePath = avatarImagePath
                imageDownloadOperation = NDImageDownloaderOperation(imagePath: avatarImagePath, iconGroup: iconGroup)
                imageDownloadOperation.downloadCompletionBlock = {[weak self](imagePath: String?) in
                    dispatch_async(dispatch_get_main_queue(), {
                        if let imagePath = imagePath {
                            self?.setImageWithAvatarImagePath(imagePath, iconGroup: iconGroup)
                        }
                    })
                }
                NDImageDownloader.imageDownloader.imageDownloaderQueue.addOperation(imageDownloadOperation)
            }
        } else {
            dateLabelLeadingConstraint.constant = 5.0
            avatarImageView.hidden = true
        }
    }
    
    func setImageWithAvatarImagePath(avatarImagePath: String, iconGroup: IconGroup?) -> Bool {
        var isSet = false
        let filePath = NDImageDownloader.imageDownloader.getFilePath(avatarImagePath, iconGroup: iconGroup)
        if NSFileManager.defaultManager().fileExistsAtPath(filePath) {
            if let data = NSData(contentsOfFile: filePath) {
                self.avatarImageView.image = UIImage(data: data)
                isSet = true
            } else {
                self.avatarImageView.image = UIImage(named: "AppIcon40x40")
            }
        }
        return isSet
    }
}

//
//  NDTabbarController.swift
//  News
//
//  Created by Sachin Vas on 7/15/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import UIKit

class NDTabbarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let imageView = UIImageView(frame: CGRect(x: 0,y: 0,width: 10,height: 25))
        imageView.image = UIImage(named: "datalicious-logo-default-256.png")
        self.navigationItem.titleView = imageView
    }
}

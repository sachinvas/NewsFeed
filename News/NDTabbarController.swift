//
//  NDTabbarController.swift
//  News
//
//  Created by Sachin Vas on 7/15/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation
import UIKit

class NDTabbarController: UITabBarController, UITabBarControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        let imageView = UIImageView(frame: CGRect(x: 0,y: 0,width: 10,height: 25))
        imageView.image = UIImage(named: "datalicious-logo-default-256.png")
        self.navigationItem.titleView = imageView
    }
    
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        if let navigationController = viewController as? UINavigationController {
            if navigationController.topViewController!.isKindOfClass(NDTwitterViewController) {
            }
        }
    }
    
}

//
//  NDAuthenticationViewController.swift
//  News
//
//  Created by Sachin Vas on 7/25/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import TwitterKit

class NDAuthenticationViewController: UIViewController {
    
    @IBOutlet weak var authWebView: UIWebView!
    var webViewURL: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Twitter.sharedInstance().logInWithMethods([.WebBased]) { (session, error) in
            
        }
//        let logInButton = TWTRLogInButton { (session, error) in
//            if let unwrappedSession = session {
//                let alert = UIAlertController(title: "Logged In",
//                    message: "User \(unwrappedSession.userName) has logged in",
//                    preferredStyle: UIAlertControllerStyle.Alert
//                )
//                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
//                self.presentViewController(alert, animated: true, completion: nil)
//            } else {
//                NSLog("Login error: %@", error!.localizedDescription);
//            }
//        }
//        logInButton.loginMethods = [.WebBased]
//        
//        logInButton.center = self.view.center
//        self.view.addSubview(logInButton)
    }
    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//        if !authWebView.loading && authWebView.request == nil {
//            let urlRequest = NSURLRequest(URL: webViewURL)
//            authWebView.loadRequest(urlRequest)
//        }
//    }
}

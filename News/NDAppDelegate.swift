//
//  NDAppDelegate.swift
//  News
//
//  Created by Sachin Vas on 7/14/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import Fabric
import TwitterKit
import GoogleSignIn
import PinterestSDK

let twitterConsumerKey = "uyBkpqDnjRIoQMrwGOG3ZaDhL"
let twitterConsumerSecret = "5HpHDhBppjVleRsEGZvW7oZumdfPAXqtOdtnMOogLfMNYteEZ9"
let pinterestAppId = "4848557171236940398"

@UIApplicationMain
@objc class NDAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Twitter.sharedInstance().startWithConsumerKey(twitterConsumerKey, consumerSecret: twitterConsumerSecret)
        Fabric.with([Twitter.self])
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [NSForegroundColorAttributeName:UIColor(red: (204.0/255.0), green: 0.0, blue: 0.0, alpha: 1.0),
                NSFontAttributeName:UIFont(name: "Helvetica-bold", size: 18.0)!
            ],
            forState: .Normal)
        PDKClient.configureSharedInstanceWithAppId(pinterestAppId)
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
//        self.saveContext()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if Twitter.sharedInstance().application(application, openURL: url, options: annotation as! [NSObject : AnyObject]) {
            return true
        } else if GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        } else if PDKClient.sharedInstance().handleCallbackURL(url) {
            return true
        }
        return false
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        var sourceApp = "com.datalicious.news"
        if #available(iOS 9.0, *) {
            sourceApp = options[UIApplicationOpenURLOptionsSourceApplicationKey] as! String
        }
        if Twitter.sharedInstance().application(app, openURL: url, options: options) {
            return true
        } else if GIDSignIn.sharedInstance().handleURL(url, sourceApplication: sourceApp, annotation: options) {
            return true
        } else if PDKClient.sharedInstance().handleCallbackURL(url) {
            return true
        }
        return false
    }
}


extension UIApplication {
    override public class func initialize() {
        var onceToken : dispatch_once_t = 0;
        dispatch_once(&onceToken) {
            let originalSelector = #selector(UIApplication.openURL(_:))
            let swizzledSelector = #selector(UIApplication.nd_openURL(_:))
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
    
    func nd_openURL(url: NSURL) -> Bool {
        if url.absoluteString.containsString("https://api.pinterest.com/oauth/?client_id=" + pinterestAppId) {
            let pinterestAuthController = NDSafariViewController()
            pinterestAuthController.request = NSURLRequest(URL: url)
            pinterestAuthController.title = "Twitter Login"
            pinterestAuthController.requriesDone = true
            let navController = UINavigationController(rootViewController: pinterestAuthController)
            UIApplication.sharedApplication().keyWindow?.rootViewController?.presentViewController(navController, animated: true, completion: nil)
            return false
        }
        return nd_openURL(url)
    }
}


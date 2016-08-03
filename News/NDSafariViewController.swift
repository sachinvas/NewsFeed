//
//  NDSafariViewController.swift
//  PinterestSDK
//
//  Created by Sachin Vas on 8/1/16.
//  Copyright © 2016 ricky cancro. All rights reserved.
//

import Foundation
import WebKit
import MBProgressHUD

class NDSafariViewController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView!
    var progressView:MBProgressHUD!
    var showNavigationOnPush:Bool = false
    var hideNavigationOnPop:Bool = false
    
    var request: NSURLRequest!
    var requriesDone: Bool = false
    
    deinit {
        webView.removeObserver(self, forKeyPath: "loading", context: nil)
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.removeFromSuperview()
        webView = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView = WKWebView(frame: view.frame)
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        progressView = MBProgressHUD.showHUDAddedTo(webView, animated: true)
        progressView.label.text = "Loading..."


        webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)

        navigationController?.setNavigationBarHidden(!showNavigationOnPush, animated: true)
        if requriesDone {
            let done = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(NDSafariViewController.done))
            navigationItem.leftBarButtonItem = done
        } else {
            navigationItem.backBarButtonItem?.title = "Back"
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if webView.URL == nil {
            webView.loadRequest(request)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isMovingFromParentViewController() {
            navigationController?.setNavigationBarHidden(!hideNavigationOnPop, animated: true)
        }
    }
    
    func done() {
        if requriesDone {
            navigationController?.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "loading" {
            if let change = change {
                if let new = change["new"] as? Int {
                    if new == 1 {
                        progressView.showAnimated(true)
                    } else {
                        progressView.hideAnimated(true)
                    }
                }
            }
        }
    }
    
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: ((WKNavigationActionPolicy) -> Void)) {
        if (navigationAction.navigationType == WKNavigationType.LinkActivated) {
            if let url = webView.URL {
                if let urlComponents = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) {
                    if urlComponents.scheme == "pdk" + pinterestAppId {
                        if UIApplication .sharedApplication().canOpenURL(url) {
                            webView.stopLoading()
                            UIApplication.sharedApplication().openURL(url)
                            done()
                            decisionHandler(WKNavigationActionPolicy.Cancel)
                            return
                        }
                    }
                }
            }
        }
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
    
    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        let alertController = UIAlertController(title: "Loading Error", message: error.localizedDescription, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: .Cancel) { (alertAction:UIAlertAction) in
            alertController.dismissViewControllerAnimated(true, completion: nil)
        }
        alertController.addAction(action)
        navigationController?.presentViewController(alertController, animated: true, completion: nil)
    }
}

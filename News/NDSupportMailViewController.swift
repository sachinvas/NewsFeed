//
//  NDSupportMailViewController.swift
//  News
//
//  Created by Sachin Vas on 8/3/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import UIKit
import MBProgressHUD

class NDSupportMailViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var inquiry: UITextView!
    
    var progressView:MBProgressHUD!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inquiry.delegate = self
        
        progressView = MBProgressHUD(view: view)
        
        let cancelBarButton = UIBarButtonItem(title: "Cancel", style: .Plain, target: self, action: #selector(NDSupportMailViewController.cancel))
        navigationItem.leftBarButtonItem = cancelBarButton
        
        let sendBarButton = UIBarButtonItem(title: "Send", style: .Plain, target: self, action: #selector(NDSupportMailViewController.send))
        navigationItem.rightBarButtonItem = sendBarButton
    }
    
    func cancel() {
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func send() {
        let validate = validateFields()
        if validate.success == false {
            let alertController = UIAlertController(title: "Required Field", message: validate.message, preferredStyle: .Alert)
            let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action:UIAlertAction) in
                alertController.dismissViewControllerAnimated(true, completion: nil)
                validate.field?.becomeFirstResponder()
            })
            alertController.addAction(action)
            navigationController?.presentViewController(alertController, animated: true, completion: nil)
        } else {
            let urlString = "http://www.datalicious.com/contact/"
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let manager = NSURLSession(configuration: configuration)
            let request = NSMutableURLRequest(URL: NSURL(string: urlString)!)
            request.HTTPMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let dataString = "PERSONAL_NAME=\(nameTextField.text!)&PHONE=\(phoneNumberField.text!)&EMAIL=\(emailField.text!)&MESSAGE=\(inquiry.text!)"
            request.HTTPBody = dataString.dataUsingEncoding(NSUTF8StringEncoding)
            progressView.showAnimated(true)
            let dataTask = manager.dataTaskWithRequest(request) {[weak self] (data:NSData?, response:NSURLResponse?, error:NSError?) in
                dispatch_async(dispatch_get_main_queue(), {
                    self?.progressView.hideAnimated(true)
                    if error == nil {
                        let alertController = UIAlertController(title: "Message Sent", message: "Your message sent successfully...", preferredStyle: .Alert)
                        let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action:UIAlertAction) in
                            alertController.dismissViewControllerAnimated(true, completion: nil)
                            validate.field?.becomeFirstResponder()
                        })
                        alertController.addAction(action)
                        self?.navigationController?.presentViewController(alertController, animated: true, completion: nil)
                    } else {
                        let alertController = UIAlertController(title: "Error Occurred", message: error?.localizedDescription, preferredStyle: .Alert)
                        let action = UIAlertAction(title: "Ok", style: .Cancel, handler: { (action:UIAlertAction) in
                            alertController.dismissViewControllerAnimated(true, completion: nil)
                            validate.field?.becomeFirstResponder()
                        })
                        alertController.addAction(action)
                        self?.navigationController?.presentViewController(alertController, animated: true, completion: nil)
                    }
                })
            }
            dataTask.resume()
        }
    }
    
    func validateFields() -> (success:Bool, field: AnyObject?, message: String?) {
        
        if let nameText = nameTextField.text where nameText.characters.count > 0 {
            //Do nothing...
        } else {
            return (false, nameTextField, "Please enter your name")
        }
        
        if let phoneText = phoneNumberField.text where phoneText.characters.count > 0 {
            let range = NSRange(location: 0, length: phoneText.characters.count)
            let checkingPhoneNumber = NSTextCheckingResult.phoneNumberCheckingResultWithRange(range, phoneNumber: phoneText)
            if checkingPhoneNumber.resultType == .PhoneNumber && checkingPhoneNumber.range.location == 0 && checkingPhoneNumber.range.length == phoneText.characters.count {
                //Do nothing...
            } else {
                return (false, phoneNumberField, "Phone number is not valid")
            }
        } else {
            return (false, phoneNumberField, "Please enter your phone number")
        }
        
        if let emailText = emailField.text where emailText.characters.count > 0 {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            let isValidPhoneNumber = emailPredicate.evaluateWithObject(emailText)
            if !isValidPhoneNumber {
                return (false, emailField, "Email id is not valid")
            }
        } else {
            return (false, emailField, "Please enter your email id")
        }
        
        if let inquiryText = inquiry.text where inquiryText.characters.count > 0 {
            //Do nothing...
        } else {
            return (false, inquiry, "Please enter your inquiry")
        }
        
        return (true, nil, nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        textView.text = ""
    }
}

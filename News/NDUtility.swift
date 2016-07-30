//
//  NDUtility.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation

class NDUtility: NSObject {
    
    class var utility: NDUtility {
        struct Singleton {
            static let instance = NDUtility()
        }
        return Singleton.instance
    }
    
    lazy var newsDateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy hh:mm:ss +zzzz"
        return dateFormatter
    }()
    
    lazy var newsDateDisplayFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy hh:mm"
        return dateFormatter
    }()
    
    func dictionaryFromResponse(response: String) -> Dictionary<String, String> {
        var dictionary = Dictionary<String, String>()
        let fields = response.componentsSeparatedByString("&");
        
        for field in fields {
            let pair = field.componentsSeparatedByString("=")
            if pair.count == 2 {
                let key = pair[0]
                var value = pair[1].stringByRemovingPercentEncoding
                value = value?.stringByReplacingOccurrencesOfString("+", withString: " ")
                if dictionary[key] != nil {
                    print("duplicate key")
                }
                dictionary[key] = value
            }
        }
        return dictionary
    }
}
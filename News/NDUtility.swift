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
}
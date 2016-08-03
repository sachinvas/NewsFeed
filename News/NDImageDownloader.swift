//
//  NDImageDownloader.swift
//  News
//
//  Created by Sachin Vas on 8/3/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

import Foundation

let iconDirectory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] + "/Icons/"

enum IconGroup {
    case YouTube
    case Pinterest
}

class NDImageDownloader: NSObject {
    
    var imageDownloaderQueue: NSOperationQueue
    
    class var imageDownloader: NDImageDownloader {
        struct Singleton {
            static let instance = NDImageDownloader()
        }
        return Singleton.instance
    }
    
    override init() {
        imageDownloaderQueue = NSOperationQueue()
        imageDownloaderQueue.qualityOfService = .UserInitiated
        imageDownloaderQueue.name = "NDImageDownloaderQueue"
        imageDownloaderQueue.maxConcurrentOperationCount = 1
        if !NSFileManager.defaultManager().fileExistsAtPath(iconDirectory) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(iconDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch let error {
                print(error)
            }
        }
        super.init()
    }
    
    func getFilePath(imagePath: String, iconGroup: IconGroup?) -> String {
        var filePath = imagePath
        if let iconGrp = iconGroup {
            let pathComponents = (imagePath as NSString).pathComponents
            let count = pathComponents.count
            switch iconGrp {
            case .Pinterest:
                let pinterestPath = iconDirectory + "Pinterest/"
                if !NSFileManager.defaultManager().fileExistsAtPath(pinterestPath) {
                    do {
                        try NSFileManager.defaultManager().createDirectoryAtPath(pinterestPath, withIntermediateDirectories: true, attributes: nil)
                    } catch let error {
                        print(error)
                    }
                }
                if count > 0 {
                    filePath = "\(pathComponents[count - 1])"
                }
                filePath = pinterestPath + filePath
            case .YouTube:
                let youTubePath = iconDirectory + "YouTube/"
                if !NSFileManager.defaultManager().fileExistsAtPath(youTubePath) {
                    do {
                        try NSFileManager.defaultManager().createDirectoryAtPath(youTubePath, withIntermediateDirectories: true, attributes: nil)
                    } catch let error {
                        print(error)
                    }
                }
                if count > 0 {
                    filePath = pathComponents[count - 1]
                }
                if count > 1 {
                    filePath = "\(pathComponents[count - 2])-\(filePath)"
                }
                filePath = youTubePath + filePath
            }
        }
        return filePath
    }
}

class NDImageDownloaderOperation: NSOperation {
    
    // MARK: - Types
    
    enum State {
        case Ready, Executing, Finished
        func keyPath() -> String {
            switch self {
            case Ready:
                return "isReady"
            case Executing:
                return "isExecuting"
            case Finished:
                return "isFinished"
            }
        }
    }
    
    // MARK: - Properties
    
    var state = State.Ready {
        willSet {
            willChangeValueForKey(newValue.keyPath())
            willChangeValueForKey(state.keyPath())
        }
        didSet {
            didChangeValueForKey(oldValue.keyPath())
            didChangeValueForKey(state.keyPath())
        }
    }
    
    override var ready: Bool {
        return super.ready && state == .Ready
    }
    
    override var executing: Bool {
        return state == .Executing
    }
    
    override var finished: Bool {
        return state == .Finished
    }
    
    var imagePath: String
    private var iconGroup: IconGroup?
    var downloadCompletionBlock:((String?)->())!
    private var dataTask: NSURLSessionDataTask?
    
    init(imagePath imgPath: String, iconGroup iconGrp: IconGroup?) {
        imagePath = imgPath
        iconGroup = iconGrp
        super.init()
    }
    
    deinit {
        downloadCompletionBlock = nil
        dataTask = nil
    }
        
    override func start() {
        if self.cancelled {
            self.finished
            self.state = .Finished
        } else {
            self.state = .Executing
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let manager = NSURLSession(configuration: configuration)
            let request = NSURLRequest(URL: NSURL(string: imagePath)!)
            dataTask = manager.dataTaskWithRequest(request) {[weak self] (data:NSData?, response:NSURLResponse?, error:NSError?) in
                if error == nil {
                    if let data = data {
                        if let imagePath = self?.imagePath {
                            let filePath = NDImageDownloader.imageDownloader.getFilePath(imagePath, iconGroup: self?.iconGroup)
                            if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                                NSFileManager.defaultManager().createFileAtPath(filePath, contents: data, attributes: nil)
                            } else {
                                print("Error file already exists locally")
                            }
                            self?.downloadCompletionBlock(imagePath)
                        }
                    } else {
                        print("data not found")
                        self?.downloadCompletionBlock(nil)
                    }
                } else {
                    print(error)
                    self?.downloadCompletionBlock(nil)
                }
                self?.state = .Finished
            }
            dataTask?.resume()
        }
    }
    
    override func cancel() {
        self.state = .Finished
        dataTask?.cancel()
    }
}
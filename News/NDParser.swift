//
//  NDParser.swift
//  News
//
//  Created by Sachin Vas on 7/18/16.
//  Copyright © 2016 Sachin Vas. All rights reserved.
//

let item = "item"
let category = "category"
let xml_categories = "categories"

import Foundation

class NDParser: NSObject, NSXMLParserDelegate {
    
    var xmlParser: NSXMLParser
    init(xmlData: NSData) {
        xmlParser = NSXMLParser(data: xmlData)
        super.init()
        xmlParser.delegate = self
    }
    
    func parse() {
        xmlParser.parse()
    }
    
    func parserDidEndDocument(parser: NSXMLParser) {
        xmlParser.abortParsing()
        xmlParser.delegate = nil
    }
}

class NDBlogItemParser: NDParser {
    
    private var startParsing:Bool = false
    private var parsingElementName:String = ""
    var blogItems:[Dictionary<String, AnyObject>] = []
    private var element:Dictionary<String, AnyObject>! = [:]
    private var categoryArray: [String] = []
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if startParsing {
            parsingElementName = elementName
        } else {
            if elementName == item {
                startParsing = true
                element = [:]
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
        if startParsing {
            if let string = String(data: CDATABlock, encoding: NSUTF8StringEncoding) {
                let value = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                if value.characters.count > 0 {
                    if parsingElementName == category {
                        categoryArray.append(value)
                    } else {
                        element[parsingElementName] = value
                    }
                }
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if startParsing {
            let value = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if value.characters.count > 0 {
                if parsingElementName == category {
                    categoryArray.append(value)
                } else {
                    element[parsingElementName] = value
                }
            }
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == item {
            startParsing = false
            if categoryArray.count > 0 {
                element[xml_categories] = categoryArray
            }
            blogItems.append(element)
            element = nil
        }
    }
}

//
//  JSONParser.swift
//  LoginSwift
//
//  Created by Tanay Singhal on 12/21/16.
//  Copyright © 2016 Tanay Singhal. All rights reserved.
//

import UIKit

class JSONParser {
    
    func parseJsonAsString(json: AnyObject, field: String) -> String? {
        if let result = (json[field] as? String) {
            return result
        }
        else {
            //print("\(field) not found")
            return nil
        }
    }
    func parseJsonAsInt(json: AnyObject, field: String) -> Int? {
        if let result = (json[field] as? Int) {
            return result
        }
        else {
            //print("\(field) not found")
            return nil
        }
    }
    func parseJsonAsDouble(json: AnyObject, field: String) -> Double? {
        if let result = (json[field] as? Double) {
            return result
        }
        else {
            //print("\(field) not found")
            return nil
        }
    }
    func parseJsonAsBool(json: AnyObject, field: String) -> Bool? {
        if let result = (json[field] as? Bool) {
            return result
        }
        else {
            //print("\(field) not found")
            return nil
        }
    }
    
}

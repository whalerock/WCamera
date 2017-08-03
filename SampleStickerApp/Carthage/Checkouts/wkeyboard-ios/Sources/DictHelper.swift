//
//  DictHelper.swift
//  WKeyboard
//
//  Created by Animesh Manglik on 5/22/17.
//  Copyright © 2017 Whalerock Industries. All rights reserved.
//

import Foundation
public func dictValue(dict: [String: Any], forKeyPath keyPath: String) -> Any?{
    let keys = keyPath.components(separatedBy: ".")
    switch keys.count{
    case 1:
        return dict[keys[0]]
    case (2..<Int.max):
        var running = dict

        let exceptLastOne = keys[ 0 ..< (keys.count - 1) ]
        for key in exceptLastOne{
            if let r = running[key] as? [String: Any]{
                running = r
            }else{
                return nil
            }
        }
        return running[keys.last!]
    default:
        return nil
    }
}


public func dictSetValue( dict: inout [String: Any], value: Any, keys: ArraySlice<String>){
    switch keys.count{
    case 1:
        return dict[keys.first!] = value
    case (2..<Int.max):
        let key = keys.first!
        var subDict = (dict[key] as? [String: Any]) ?? [:]
        dictSetValue(dict: &subDict, value: value, keys: keys.dropFirst())
        dict[key] = subDict as Any
        return
    default:
        return
    }
}


public func dictSetValue( dict: inout [String: Any], value: Any, forKeyPath keyPath: String){
    let keys = keyPath.components(separatedBy: ".")
    dictSetValue(dict: &dict, value: value, keys: ArraySlice(keys))
}


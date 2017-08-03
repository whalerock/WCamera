//
//  WConfig.swift
//  wconfig
//
//  Created by Sam Phomsopha on 7/25/16.
//  Copyright © 2016 Sam Phomsopha. All rights reserved.
//

import Foundation

/// WConfig provides access to config values base on environment
open class WConfig {
    
    open var defaultDataSource:DefaultConfigDataSource?
    open var productionDataSource:ProductionConfigDataSource?
    open var remoteDefaultDataSource:RemoteDefaultConfigDataSource?
    open var remoteProductionDataSource:RemoteProductionConfigDataSource?
    
    open static let sharedInstance = WConfig()
    open static let sharedTestCaseInstance = WConfig()
    
    fileprivate var environment = WEnvironment.production
    
    fileprivate init() {}
    
    /**
     Lookup configuration value by key
     
     - parameter key: key for lookup
     
     - returns: Any found for key
     */
    open func get(_ key: String) -> Any? {
                
        let keyArrs = key.components(separatedBy: ".")
    
        var foundValue: Any?
        
        //default lookup
        if let lookUpDictionary = defaultDataSource?.configData {
            foundValue = lookupValueInDictionary(lookUpDictionary as Dictionary<String, Any>, lookUpKeys: keyArrs)
        }
        
        //default remote lookup
        if let remoteLookUpDictionary = remoteDefaultDataSource?.configData {
            let remotefoundValue = lookupValueInDictionary(remoteLookUpDictionary as Dictionary<String, Any>, lookUpKeys: keyArrs)

            //if foundValue is a Dictionary, compare it to previous Dictionary and pick up any missing keys
            if remotefoundValue is NSDictionary && foundValue is NSDictionary {
                var mutableRemoteValue = remotefoundValue as! Dictionary<String, Any>
                if let value = foundValue as? Dictionary<String, Any> {
                    value.forEach{(key, fValue) in
                        if mutableRemoteValue[key] == nil {
                            mutableRemoteValue[key] = fValue
                        }
                    }
                }
                
                foundValue = mutableRemoteValue as Any?
            } else {
                if remotefoundValue != nil {
                    foundValue = remotefoundValue
                }
            }
            
        }
        
        //production lookup
        if environment == .production {
            if let prodLookupDictionary = productionDataSource?.configData {
                if let prodFoundValue = lookupValueInDictionary(prodLookupDictionary as Dictionary<String, Any>, lookUpKeys: keyArrs) {
                    //if prodFoundValue is a Dictionary, compare it to previous foundValue Dictionary and pick up any misisng keys
                    if prodFoundValue is NSDictionary && foundValue is NSDictionary {
                        var mutableRemoteValue = prodFoundValue as! Dictionary<String, Any>
                        if let value = foundValue as? Dictionary<String, Any> {
                            value.forEach{(key, fValue) in
                                if mutableRemoteValue[key] == nil {
                                    mutableRemoteValue[key] = fValue
                                }
                            }
                        }
                        
                        foundValue = mutableRemoteValue as Any?
                    } else {
                            foundValue = prodFoundValue
                    }
                }
            }
            
            //production remote lookup
            if let remoteLookUpDictionary = remoteProductionDataSource?.configData {
                let remotefoundValue = lookupValueInDictionary(remoteLookUpDictionary as Dictionary<String, Any>, lookUpKeys: keyArrs)
                
                //if foundValue is a Dictionary, compare it to previous Dictionary and pick up any missing keys
                
                if remotefoundValue is NSDictionary && foundValue is NSDictionary {
                    var mutableRemoteValue = remotefoundValue as! Dictionary<String, Any>
                    if let value = foundValue as? Dictionary<String, Any> {
                        value.forEach{(key, fValue) in
                            if mutableRemoteValue[key] == nil {
                                mutableRemoteValue[key] = fValue
                            }
                        }
                    }
                    
                    foundValue = mutableRemoteValue as Any?
                } else {
                    if remotefoundValue != nil {
                        foundValue = remotefoundValue
                    }
                }
            }
        }
        
        return foundValue
    }

    open func all() -> [String: Any] {
        var result:[String: Any] = [:]

        if let defaultLocal = defaultDataSource?.configData {
            result = defaultLocal
        }

        if let defaultRemote = remoteDefaultDataSource?.configData {
            result = deepMerge(result, defaultRemote)
        }

        if environment == .production {
            if let prodLookupDictionary = productionDataSource?.configData {
                result = deepMerge(result, prodLookupDictionary)
            }

            if let prodRemote = remoteProductionDataSource?.configData {
                result = deepMerge(result, prodRemote)
            }
        }

        return result
    }


    private func deepMerge(_ d1:[String:Any], _ d2:[String:Any]) -> [String:Any] {
        var result = [String:Any]()
        for (k1,v1) in d1 {
            result[k1] = v1
        }
        for (k2,v2) in d2 {
            if v2 is [String:Any], let v1 = result[k2], v1 is [String:Any] {
                result[k2] = deepMerge(v1 as! [String:Any], v2 as! [String:Any])
            } else {
                result[k2] = v2
            }
        }
        return result
    }

    /**
     Set environment for WConfig
     
     - parameter environment: environment variable
     */
    open func setEnvironment(_ environment: WEnvironment) {
        self.environment = environment
    }
    
    fileprivate func lookupValueInDictionary(_ lookUpDictionary: Dictionary<String, Any>, lookUpKeys: [String]) -> Any? {
        
        var foundValue: Any?
        var tempDictionary = lookUpDictionary
        for lookupKey in lookUpKeys {
            if let value = tempDictionary[lookupKey] {
                if value is NSDictionary {
                    tempDictionary = (value as? Dictionary<String, Any>)!
                }
                
                foundValue = value
            } else {
                foundValue = nil
            }
        }
        
        return foundValue
    }

    
}

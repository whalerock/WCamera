//
//  Config.swift
//  WCamera
//
//  Created by David Hoofnagle on 8/2/17.
//  Copyright © 2017 Whalerock. All rights reserved.
//

import Foundation
import WConfig
import WKeyboard

public class Config {
    
    internal static func sharedInstance() -> WConfig {
        let wconfig = WConfig.sharedInstance
        
        guard wconfig.defaultDataSource == nil else {
            return wconfig
        }
        
        if let environment = Bundle.main.object(forInfoDictionaryKey: "Configuration") {
            if environment as! String == "Debug" {
                wconfig.setEnvironment(WEnvironment.dev)
            }
        }
        wconfig.defaultDataSource = DefaultConfig()
        wconfig.productionDataSource = ProductionConfig()
        
        return wconfig
    }
    
    public class func fetchPayload(completion: (([String: AnyObject])->Void)?) {
        WKeyboard.api.fetchPayload {
            if let configDict = WKeyboard.api.config?.value(forKey: "configurations") as? [String: AnyObject] {
                completion?(configDict)
            }
        }
    }
    
    
}


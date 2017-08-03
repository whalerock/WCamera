//
//  WRILogger.swift
//  Kimoji
//
//  Created by aramik on 4/22/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation

public enum WRILoggerType {
    case log
    case warning
    case error
}

open class WRILogger {
    open static func log(_ file:String, type:WRILoggerType, message:String) {
        var logString = ""
        if let sourceFile = URL(string: file)?.lastPathComponent.replacingOccurrences(of: ".swift", with: "") {
            logString = "[\(sourceFile)]:"
            
        } else {
            logString = "[UnknownSender]:"
        }
        
        switch type {
        case .log:
            print(logString, message)
        case .warning:
        //    NewRelic.recordEvent("WARNING", attributes: ["message":message])
            print(logString, "WARNING", message)
            
        case .error:
        //    NewRelic.recordEvent("ERROR", attributes: ["message":message])
            print(logString, "ERROR", message)
        }
    }
 }

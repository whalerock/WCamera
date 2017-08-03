//
//  DeviceInfo.swift
//  WUtilities
//
//  Created by aramik on 7/10/16.
//
//

import Foundation
import UIKit

open class WDeviceInfo {

    public init() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    open var uuid: String {
        return UUID().uuidString
    }

    open var name: String {
        return UIDevice.current.name
    }

    open var orientation: Int {
        return UIDevice.current.orientation.rawValue
    }

    open var batteryLevel: Float {
        return UIDevice.current.batteryLevel
    }

    open var batteryState: Int {
        return UIDevice.current.batteryState.rawValue
    }

    open var systemName: String {
        return UIDevice.current.systemName
    }

    open var systemVersion: String {
        return UIDevice.current.systemVersion
    }

    open var vendorIdentifier: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? ""
    }

    open var model: String {
        return UIDevice.current.model
    }

    open var type: String {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return "iPad"
        case .phone:
            return "iPhone"
        case .tv:
            return "AppleTV"
        default:
            return "Unspecified"

        }
    }


    /// Dictionary of device attributes
    open var infoDict: Dictionary<String,Any> {
        var tempDict = Dictionary<String,Any>()
        tempDict["uuid"] = self.uuid
        tempDict["name"] = self.name
        tempDict["model"] = self.model
        tempDict["type"] = self.type
        tempDict["systemName"] = self.systemName
        tempDict["systemVersion"] = self.systemVersion
        tempDict["orientation"] = self.orientation
        tempDict["batteryLevel"] = self.batteryLevel
        tempDict["batteryState"] = self.batteryState
        tempDict["vendorIdentifier"] = self.vendorIdentifier
        if WUtilities.location.currentLocation != nil {
            var locationDict = Dictionary<String,String>()
            locationDict["lat"] = "\(WUtilities.location.currentLocation!.coordinate.latitude)"
            locationDict["long"] = "\(WUtilities.location.currentLocation!.coordinate.longitude)"
            tempDict["location"] = locationDict
        }
        return tempDict
    }
    
    
}

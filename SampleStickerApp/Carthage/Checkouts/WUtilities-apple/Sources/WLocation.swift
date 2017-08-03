//
//  WLocation.swift
//  WUtilities
//
//  Created by aramik on 7/10/16.
//
//

import Foundation
import CoreLocation


open class WLocation {

    /// CLLocationManager instance for complete access to delegate methods as needed.
    open var manager = CLLocationManager()
    open var consoleLogs: Bool = false


    public init() {
        self.manager.startUpdatingLocation()
    }

    /// Get current CLLocation authorizationStatus
    open var authorizationStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    /// Get current location of device if authorized.
    open var currentLocation: CLLocation? {
        return CLLocationManager().location
    }

    /**
     Prompt the user for 'Always' location authorization; Use 'WhenInUse' unless location is needed while app is running in background mode.
     */
    open func requestAlwaysAuthorization() {

        if let _ = WUtilities.getValueFromPLIST(key: "NSLocationAlwaysUsageDescription", file: "Info", ofType: "plist") {
            if self.authorizationStatus != CLAuthorizationStatus.authorizedAlways {
                self.manager.requestAlwaysAuthorization()
                self.log("Requesting Always authorization.")
            } else {
                self.log("Always authorization aborted; User already authorized this.")
            }
        } else {
            print("[WLocation]: Warning 'NSLocationAlwaysUsageDescription' Key missing from Info.plist")
        }
    }

    /**
     Prompt the user for 'WhenInUse' location authorization.
     */
    open func requestWhenInUseAuthorization() {
        if let _ = WUtilities.getValueFromPLIST(key: "NSLocationWhenInUseUsageDescription", file: "Info", ofType: "plist") {
            if self.authorizationStatus != CLAuthorizationStatus.authorizedWhenInUse {
                self.manager.requestWhenInUseAuthorization()
                self.log("Requesting WhenInUse authorization.")
            } else {
                self.log("WhenInUse authorization aborted; User already authorized this.")
            }
        } else {
            print("[WLocation]: Warning 'NSLocationWhenInUseUsageDescription' Key missing from Info.plist")
        }
    }


    /**
     Used to print log messages, if enabled

     - parameter message: Log message
     */
    fileprivate func log(_ message:String) {
        if self.consoleLogs {
            print("[WLocation]: \(message)");
        }
    }

}

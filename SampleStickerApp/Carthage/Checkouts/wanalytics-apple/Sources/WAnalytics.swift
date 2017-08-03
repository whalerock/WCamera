//
//  WAnalytics.swift
//  WAnalytics
//
//  Created by Aramik on 7/20/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

import Foundation
import WConfig
import AdSupport

/// WAnalytics singleton class used to setup and manage tracking through the framework.
/**
 * For documentation of requirements,
 * @see https://docs.google.com/spreadsheets/d/1OF9mSX2rE3_FakQQ1TmTxAqyY38wukPlav2cqhxzvpU/edit#gid=0
 */
open class WAnalytics {
    
    // MARK: Variables
    
    /// WAnalytics sharedInstance
    open static let manager = WAnalytics()
    
    /// Enable/Disable WAnalytics console logs
    open var loggingEnabled: Bool = true
    
    /// Reference to Google Analytics defaultTracker, only made available through the 'setupGA:accountID' function.
    open fileprivate(set) var gaDefaultTracker: GAITracker?
    
    // MARK: Lifecycle
    
    /**
     Use this function to auto configure all Services via WConfig framework
     */
    open func autoConfigure() {
        if let gaAccountId = WConfig.sharedInstance.get("analytics.ga.accountId") as? String {
            setupGA(gaAccountId)
            log("GoogleAnalytics setup with \(gaAccountId)")
        }
    }

    public class var tracker: GAITracker {
        get {
            return GAI.sharedInstance().defaultTracker
        }
    }

    
    // MARK: Setup functions
    
    /**
     Use this function in your AppDelegate's 'application:didFinishLaunchingWithOptions:' to setup Google Analtyics service.
     
     - parameter accountID: Application Tracking ID provided by GA; (i.e. 'UA-54312694-31')
     */
    open func setupGA(_ accountID: String) {
        GAI.sharedInstance().trackUncaughtExceptions = false
        GAI.sharedInstance().dispatchInterval = 20;
        gaDefaultTracker = GAI.sharedInstance().tracker(withTrackingId: accountID)
        gaDefaultTracker?.allowIDFACollection = true
        self.log("setup Google Analytics with account: \(accountID)")
    }
    
    
    /**
     Helpers for different types of events
     */
    
    open func sendEvent(_ category:WAnalyticsCategory, action:WAnalyticsAction) {
        WAnalytics.sendEvent(category, action:action)
    }
    
    open func sendEvent(_ category:WAnalyticsCategory, action:WAnalyticsAction, label:String)
    {
        WAnalytics.sendEvent(category, action:action, label:label)
    }
    
    open func sendEvent(_ category:WAnalyticsCategory, action:WAnalyticsAction, label: String, iapProductId:String, iapTransactionId:String) {
        WAnalytics.sendEvent(category, action:action, label:label, iapProductId: iapProductId, iapTransactionId: iapTransactionId)
    }
    

    open func sendEvent(_ category:WAnalyticsCategory, action:WAnalyticsAction, label:String?, contentId: String?, contentCategory: String?, contentType: String?, contentName: String?)
    {
        WAnalytics.sendEvent(category, action: action, label: label, contentId: contentId, contentCategory: contentCategory, contentType: contentType, contentName: contentName)
    }

    open func sendScreen(_ name: String) {
        WAnalytics.sendScreen(name)
    }

    
    // MARK: Tracking functions
    
    /**
     Send a screen view
     */
    
    public class func sendScreen(_ name:String) {
        setupFields()

        tracker.set(kGAIScreenName, value:name)
        
        let dict: NSMutableDictionary = GAIDictionaryBuilder.createScreenView().build()
        
        var params = [String: Any]()
        
        dict.allKeys.forEach { (item) in
            params[item as! String] = dict[item]
        }
        
        tracker.send(params)
        GAI.sharedInstance().dispatch()
    }


    /**
     Send a fully formed GA event
     */
    
    public class func sendEvent(_ category:WAnalyticsCategory, action:WAnalyticsAction, label:String? = nil, contentId:String? = nil, contentCategory:String? = nil, contentType:String? = nil, contentName:String? = nil, iapProductId: String? = nil, iapTransactionId: String? = nil){

        setupFields(contentId, contentCategory: contentCategory, contentType: contentType, contentName: contentName, iapProductId: iapProductId, iapTransactionId: iapTransactionId)


        let dict: NSMutableDictionary = GAIDictionaryBuilder.createEvent(withCategory: category.value, action: action.value, label:label, value: nil).build()
        var params = [String: Any]()
        
        dict.allKeys.forEach { (item) in
            params[item as! String] = dict[item]
        }
        
        tracker.send(params)
        GAI.sharedInstance().dispatch()
    }
    
    fileprivate class func setupFields(_ contentId:String? = nil, contentCategory:String? = nil, contentType:String? = nil, contentName:String? = nil, iapProductId: String? = nil, iapTransactionId: String? = nil)
    {
        // CD21: version
        tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.version.value), value:"1")

        // CD22: Set device ID for all events
        tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.idfv.value), value:UIDevice.current.identifierForVendor!.uuidString)

        // CD23: Set IDFA for all events
        tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.idfa.value), value: ASIdentifierManager.shared().advertisingIdentifier.uuidString)

        // CD42: Set IAP product ID
        if let iapProductId = iapProductId {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.iapProductId.value), value: iapProductId)
        } else {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.iapProductId.value), value: nil)
        }
        
        // CD43: Set IAP transaction ID
        if let iapTransactionId = iapTransactionId {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.iapTransactionId.value), value: iapTransactionId)
        } else {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.iapTransactionId.value), value: nil)
        }
        
        // CD61: Set content ID
        if let id = contentId
        {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentId.value), value: id)
        } else {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentId.value), value: nil)
        }
        // CD63: Set content Cateogry
        if let id = contentCategory
        {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentCategory.value), value: id)
        } else {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentCategory.value), value: nil)
        }
        // CD65: Set content Type
        if let id = contentType
        {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentType.value), value: id)
        } else {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentType.value), value: nil)
        }

        // CD68: Set content Name
        if let id = contentName
        {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentName.value), value: id)
        } else {
            tracker.set(GAIFields.customDimension(for: WAnalyticsDimension.contentName.value), value: nil)
        }
    }

    // MARK: Additional Helpers
    
    /**
     WRI custom logger which provides ability to enable/disable logging per class basis. Makes for cleaner debug console when needed.
     - parameter type:    See WRILoggerType
     - parameter message: Message you want to log
     */
    fileprivate func log(_ message:String) {
        guard self.loggingEnabled else {
            return
        }
        print("[WAnalytics]:", message)
    }
    
}

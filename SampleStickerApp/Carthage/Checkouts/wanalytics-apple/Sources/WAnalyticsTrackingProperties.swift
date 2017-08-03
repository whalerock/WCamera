//
//  WAnalyticsTrackingProperies.swift
//  WAnalytics
//
//  Created by Aramik on 7/21/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

import Foundation

/**
 *  WAnalytics Universal strucutre for storing properties that will be used for tracking through each service.
 */
public struct WAnalyticsTrackingProperties {
    
    // MARK: Properties
    /// A unique tracking id or event name. (Required)
    public var trackingID: String!
    
    /// The category or view the this event falls under. (Required)
    public var trackingCategory: String!
    
    /// The action that triggered this event. In most cases this action will be prepended with the trackingID. (i.e. trackingID: 'howtoinstallbutton' action: 'tapped' will actually track the event as 'howtoinstallbuttontapped' [Required]
    public var trackingAction: String!
    
    /// Additional information to be passed
    public var trackingLabel: String!
    
    /// A unique identifier that represents the associated content, anything from publishable id to image url.  This will also be passed as a customDimension(2)
    public var trackingContentID: String!
    
    /// The devices UUIDString if available.
    fileprivate var trackingDeviceID: String!
    
    /// An array of custom dimension values that will be included when tracking with GA. Order is very important as GA's custom dimensions are tracked with an index.  Automatically the first and second dimensions will be pre populated with (1)deviceUUID and (2)trackingContentID
    public var customDimension: [String]!
    
    /// A dictionary of values that will be included when tracking with NewRelic.  Similar to 'customDimensions' for GA, this will also come pre populated with device UUID
    public var customInfo: Dictionary<String,String>!

    
    // MARK: Functions
    /**
     Create an instance of WAnalytics universal tracking properties.
     
     - parameter id:               A unique tracking id or event name. (Required)
     
     - parameter category:         The category or view the this event falls under. (Required)
     
     - parameter action:           The action that triggered this event. In most cases this action will be prepended with the trackingID. (i.e. trackingID: 'howtoinstallbutton' action: 'tapped' will actually track the event as 'howtoinstallbuttontapped' [Required]
     
     - parameter label:            Additional information to be passed
     
     - parameter contentID:        A unique identifier that represents the associated content, anything from publishable id to image url.  This will also be passed as a customDimension(2)
     
     - parameter customDimensions: An array of custom dimension values that will be included when tracking with GA. Order is very important as GA's custom dimensions are tracked with an index.  Automatically the first and second dimensions will be pre populated with (1)deviceUUID and (2)trackingContentID
     
     - parameter customInfo:       A dictionary of values that will be included when tracking with NewRelic.  Similar to 'customDimensions' for GA, this will also come pre populated with device UUID
     
     - returns: An instance of WAnalyticsTrackingProperties or nill if all required parameters are not passed.
     */
    public init?(id: String?, category: String?, action: String?, label: String?, contentID: String?, customDimensions: [String]? = nil, customInfo: Dictionary<String,String>? = nil) {
        
        guard
            let _ = category,
            let _ = action,
            let _ = id
            else {
                return nil
        }
        
        self.trackingID = id
        self.trackingCategory = category ?? ""
        self.trackingAction = action ?? ""
        self.trackingLabel = label ?? ""
        self.trackingContentID = contentID ?? ""
        self.trackingDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? ""
        self.customDimension = customDimension ?? [String]()
        self.customInfo = customInfo ?? Dictionary<String,String>()
        
        // prepare required custom dimensions for GA
        customDimension.append(self.trackingDeviceID)
        customDimension.append(self.trackingContentID)
        
    }
}

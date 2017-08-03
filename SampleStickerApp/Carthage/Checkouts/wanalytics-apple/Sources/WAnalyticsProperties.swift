//
//  WAnalyticsProperties.swift
//  WAnalytics
//
//  Created by Aramik on 7/21/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

/**
 *  Used internal by the framework as a workaround to adding stored properties to extensions.
 */
internal struct WAnalyticsProperties {
    static var trackingID: String?
    static var trackingAction: String?
    static var trackingCategory: String?
    static var trackingLabel: String?
    static var trackingContentID: String?
    static var customDimension: [String]?
    static var customInfo: Dictionary<String,String>?
}



//
//  WAnalyticsAction.swift
//  WAnalytics
//
//  Created by Animesh Manglik on 7/27/17.
//  Copyright © 2017 Aramik. All rights reserved.
//


public enum WAnalyticsCategory: String {
    case keyboard = "keyboard"
    case containerapp = "containerapp"
    case iap = "iap"
    case messages = "messages"
    
    var value: String {
        return self.rawValue
    }
}


public enum WAnalyticsDimension: UInt
{
    case version = 21,
    idfv = 22,
    idfa = 23,
    iapProductId = 42,
    iapTransactionId = 43,
    contentId = 61,
    contentCategory = 63,
    contentType = 65,
    contentName = 68
    
    var value: UInt {
        return self.rawValue
    }
}


public enum WAnalyticsAction: String {
    case tap = "tap"
    case copied = "copied"
    case sent = "sent"
    case emoji = "emoji"
    case share = "share"
    case easteregg = "easteregg"
    case iapselect = "iapselect"
    case purchase = "purchase"
    case purchasesuccess = "purchasesuccess"
    case purchasefailed = "purchasefailed"
    case restorepurchasetap = "restorepurchasetap"
    case restoresuccess = "restoresuccess"
    case restorefailed = "restorefailed"
    case addfavorite = "addfavorite"
    
    var value: String {
        return self.rawValue
    }
}

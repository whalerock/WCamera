//
//  WAnalyticsService.swift
//  WAnalytics
//
//  Created by Aramik on 7/22/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

/**
 All available tracking providers that are integrated with this framework.  Automated tracking is sent to .ALL but only services that are setup through the manager will be used.
 */
public enum WAnalyticsService {
    
    // MARK: Values
    /**
     *  Track using all available services.
     */
    case all
    
    /**
     *  Track using GA only
     */
    case googleAnalytics
    
    /**
     *  Track using New Relic only.
     */
    case newRelic
}

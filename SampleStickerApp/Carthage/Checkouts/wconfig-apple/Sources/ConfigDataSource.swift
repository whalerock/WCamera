//
//  ConfigDataSource.swift
//  WConfig
//
//  Created by sam phomsopha on 11/29/16.
//  Copyright © 2016 Sam Phomsopha. All rights reserved.
//

import Foundation

public protocol ConfigDataSource {
    var configData: Dictionary<String, Any> { get }
}

/**
 *  Default data source for WConfig
 */
public protocol DefaultConfigDataSource:ConfigDataSource {}

public protocol RemoteDefaultConfigDataSource:ConfigDataSource {}
/**
 *  Production data source for WConfig
 */
public protocol ProductionConfigDataSource:ConfigDataSource {}

public protocol RemoteProductionConfigDataSource:ConfigDataSource {}

//
//  ConfigSpec.swift
//  wconfig
//
//  Created by Sam Phomsopha on 7/26/16.
//  Copyright © 2016 Sam Phomsopha. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import WConfig

class ConfigProdSpec: QuickSpec {
    
    override func spec() {
        describe("config class") {

            describe("config class") {
                
                let config = WConfig.sharedTestCaseInstance
                config.setEnvironment(.production)
                config.defaultDataSource = MockDefaultData()
                config.remoteDefaultDataSource = MockRemoteData()
                config.productionDataSource = MockProductionData()
                
                describe("setting production data source") {
                    config.productionDataSource = MockProductionData()
                    
                    context("retrieved values by key") {
                        it("prod value should override default") {
                            let fbValue = config.get("facebook.api_key") as! String
                            let testValue = "65789"
                            expect(fbValue).to(equal(testValue))
                        }
                        
                        it("if prod key is not found, default should be used") {
                            let endpointValue = config.get("facebook.endpoint") as! String
                            let testValue = "http://test.org"
                            
                            expect(endpointValue).to(equal(testValue))
                        }
                        
                        it("prod config and default config should be merged") {
                            let fbValue = config.get("facebook") as! [String: String]
                            let testValue = ["api_key" : "65789", "endpoint": "http://test.org", "anotherKey": "anotherValue"]
                            
                            expect(fbValue).to(equal(testValue))
                            
                        }
                    }
                }
                
            }
            
            describe("config class") {
                
                let config = WConfig.sharedTestCaseInstance
                config.setEnvironment(.production)
                config.defaultDataSource = MockDefaultData()
                config.remoteDefaultDataSource = MockRemoteData()
                config.productionDataSource = MockProductionData()
                config.remoteProductionDataSource = MockProductionRemoteData()
                
                describe("setting production data source") {
                    config.productionDataSource = MockProductionData()
                    
                    context("retrieved values by key") {
                        it("prod value should override default") {
                            let fbValue = config.get("facebook.api_key") as! String
                            let testValue = "65789Prod"
                            expect(fbValue).to(equal(testValue))
                        }
                        
                        it("if prod key is not found, default should be used") {
                            let endpointValue = config.get("facebook.endpoint") as! String
                            let testValue = "http://testprod.org"
                            
                            expect(endpointValue).to(equal(testValue))
                        }
                        
                        it("prod config and default config should be merged") {
                            let fbValue = config.get("facebook") as! [String: String]
                            let testValue = ["api_key" : "65789Prod", "endpoint": "http://testprod.org", "anotherKey": "anotherValue"]
                            
                            expect(fbValue).to(equal(testValue))
                            
                        }
                    }
                }
                
            }
            
        }
    }
    
}

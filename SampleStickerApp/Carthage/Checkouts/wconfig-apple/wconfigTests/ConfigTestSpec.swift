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

class ConfigTestSpec: QuickSpec {
    
    override func spec() {
        describe("config class") {
            
            describe("setting default data source") {
                let config = WConfig.sharedInstance
                config.setEnvironment(.dev)
                config.defaultDataSource = MockDefaultData()

                context("retrieved values by key") {
                    it("value can be retrieved by 1st level key") {
                        let fbValue = config.get("facebook") as! [String: String]
                        let testValue = ["api_key" : "12345", "endpoint": "http://test.org", "anotherKey": "anotherValue"]
                        
                        expect(testValue).to(equal(fbValue))
                    }
                    
                    it("value can be retrieved by 2nd level key") {
                        let fbApiKeyValue = config.get("facebook.api_key") as! String
                        
                        let testValue = "12345"
                        
                        expect(testValue).to(equal(fbApiKeyValue))
                    }
                    
                    it("value can be retrieved by 3rd level key") {
                        let name = config.get("owner.address.city") as! String
                        
                        let testValue = "west hollywood"
                        
                        expect(testValue).to(equal(name))
                    }
                    
                    it("value retrieved can be nested dictionary") {
                        let nestedValue: Dictionary<String, AnyObject> = config.get("owner") as! [String: AnyObject]
                        
                        let testValue: Dictionary<String, Any> = ["name": "test owner", "address": ["city": "west hollywood", "state": "ca"]]
                        expect(nestedValue["name"] as! String).to(equal(testValue["name"] as! String))
                        expect(nestedValue["address"]!["city"] as! String).to(equal("west hollywood"))
                    }
                }
                
            }
            
            describe("config class") {
                
                let config = WConfig.sharedTestCaseInstance
                config.setEnvironment(.dev)
                config.defaultDataSource = MockDefaultData()
                config.remoteDefaultDataSource =  MockRemoteData()
                
                describe("setting remote data source") {

                    context("retrieved values by key") {
                        it("remote value should override default") {
                            let fbValue = config.get("facebook.api_key") as! String
                            let testValue = "remote6789"
                            expect(fbValue).to(equal(testValue))
                        }
                        
                        it("if prod key is not found, default should be used") {
                            let endpointValue = config.get("facebook.endpoint") as! String
                            let testValue = "http://remotetest.org"
                            
                            expect(endpointValue).to(equal(testValue))
                        }
                        
                        it("prod config and default config should be merged") {
                            let fbValue = config.get("facebook") as! [String: String]
                            let testValue = ["api_key" : "remote6789", "endpoint": "http://remotetest.org", "anotherKey": "anotherValue"]
                            
                            expect(fbValue).to(equal(testValue))
                            expect(fbValue["anotherKey"]).to(equal("anotherValue"))
                        }
                    }
                }
                
            }
        }
    }
    
}

class MockDefaultData: DefaultConfigDataSource {
    let configData: Dictionary<String, Any> = ["facebook":
        ["api_key" : "12345", "endpoint": "http://test.org", "anotherKey": "anotherValue"],
        "owner": ["name": "test owner", "address": ["city": "west hollywood", "state": "ca"]]]
}

class MockRemoteData: RemoteDefaultConfigDataSource {
    let configData: Dictionary<String, Any> = ["facebook":
        ["api_key" : "remote6789", "endpoint": "http://remotetest.org"],
        "owner": ["name": "test owner", "address": ["city": "west hollywood", "state": "ca"]]]
}

class MockProductionData: ProductionConfigDataSource {
    let configData: Dictionary<String, Any> = ["facebook":
    ["api_key" : "65789", "endpoint": "http://test.org"],
    "owner": ["name": "real owner", "address": ["city": "west hollywood", "state": "ca"]]]
}

class MockProductionRemoteData: RemoteProductionConfigDataSource {
    let configData: Dictionary<String, Any> = ["facebook":
        ["api_key" : "65789Prod", "endpoint": "http://testprod.org"],
        "owner": ["name": "real owner"]]
}

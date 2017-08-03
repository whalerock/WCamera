//
//  WKNetworkAPI.swift
//  Kimoji
//
//  Created by aramik on 6/12/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation

public protocol WKNetworkAPIDelegate: class {
    func didReceiveUpdate(_ error: NSError?, config:NSDictionary?)
}

open class WKNetworkAPI {

    fileprivate var loggingEnabled: Bool = true
    fileprivate let userDefaults: UserDefaults!
    
    private var configByLocale = [String: NSDictionary]()

    open weak var delegate: WKNetworkAPIDelegate?

    public init() {
        self.userDefaults = UserDefaults.standard
        self.log(.log, message: "initialized")
    }


    fileprivate func updateConfig(config: NSDictionary, lang: [String: Any]) -> NSDictionary {

        if var translatedConfig = config as? [String: Any], let locale = lang["locale"] as? String {
            // Return local config
            if let localConfig = self.configByLocale[locale] {
                return localConfig
            }

            // config is present and lang is present
            if let translations = lang["translations"] as? [String: String] {

                let objectTypes = ["types", "categories", "packs"]
                var objectLists = [String:[[String:Any]]]()
                objectTypes.forEach {
                    objectLists[$0] = config[$0] as? [[String:Any]]
                }

                for (key, value) in translations {
                    let keyParts = key.components(separatedBy: ".")
                    let isObjectKey = objectTypes.contains(keyParts[0])
                    if isObjectKey {
                        let objectType = keyParts[0]
                        if let originalObjs = config[keyParts[0]] as? [[String:Any]] {
                            if let translatedObjIndex = originalObjs.index(where: { $0["id"] as? String == keyParts[1] }) {
                                var translatedObj = originalObjs[translatedObjIndex]
                                translatedObj[keyParts[2]] = value
                                // set the translation
                                objectLists[objectType]?[translatedObjIndex] = translatedObj
                            }
                        }
                    } else {
                        dictSetValue(dict: &translatedConfig , value: value, forKeyPath: key)
                    }
                }
                // update config with translated objectLists
                objectTypes.forEach { translatedConfig[$0] = objectLists[$0] }
            }
            let translatedDictionary = NSDictionary(dictionary: translatedConfig)
            self.configByLocale[locale] = translatedDictionary
            return translatedDictionary
        }
        return config
    }


    fileprivate func getLang(config: NSDictionary) -> [String: Any]? {
        // Find local language code
        if let langLocale = Locale.current.languageCode, let genericLangLocale = langLocale.components(separatedBy: "_").first {
            // Check if locale present in the config

            if let langs = config["langs"] as? [[String: Any]] {
                return langs.first(where: {$0["locale"] as? String == genericLangLocale })
            }
        }
        return nil
    }


    fileprivate func updatedStoredConfig() -> NSDictionary? {
        if let storedConfig = self.userDefaults.object(forKey: "wk.api.config") as? NSDictionary {
            // Is a lang found
            if let langFound = getLang(config: storedConfig) {
                // Update the config with translations
                return updateConfig(config: storedConfig, lang: langFound)
            }
            return storedConfig
        }
        return nil
    }


    open var config: NSDictionary? {
        get {
            return updatedStoredConfig()
        }
        set(config) {
            self.userDefaults.set(config, forKey: "wk.api.config")
            self.userDefaults.synchronize()
            let payloadID = config?.value(forKey: "payload_id") as? Int ?? nil
            self.log(.log, message: "StoredConfig is now set to \(payloadID)")
        }
    }

    open var assetsConfig: NSDictionary? {
        get {
            return self.userDefaults.object(forKey: "wk.api.assetsConfig") as? NSDictionary
        }
        set(config) {
            self.userDefaults.set(config, forKey: "wk.api.assetsConfig")
            self.userDefaults.synchronize()
            let payloadID = config?.value(forKey: "payload_id") as? Int ?? nil
            self.log(.log, message: "StoredAssetConfig is now set to \(payloadID)")
        }
    }


    open func fetchPayload(_ completionHandler:(()->())?) {
        let task = self.fetchJson(from: WKConfig.sharedInstance.api) { error, json in
            if error == nil {
                // save main config

                if self.config != nil && json != nil {
                    if self.config!.isEqual(json!) {
                        print("same config file!!!!!!!")
                        DispatchQueue.main.async {
                            completionHandler?()
                        }
                        return
                    }
                }

                if let assetConfigURL = json?.value(forKeyPath: "asset_json_url") as? String {
                    let assetTask = self.fetchJson(from: assetConfigURL) { assetError, assetJson in
                        if assetError == nil {
                            self.config = json
                            self.assetsConfig = assetJson
                            DispatchQueue.main.async {
                                completionHandler?()
                            }
                        } else {
                            print(assetError ?? "assetError is nil")
                        }

                    }
                    assetTask.resume()
                }
            } else {
                print(error ?? "error is nil")
            }
        }
        task.resume()
    }

    open func fetchJson(from url:String = WKConfig.sharedInstance.api, completionHandler:((_ error: NSError?, _ json:NSDictionary?)->())? = nil) -> URLSessionDataTask {
        let URL = Foundation.URL(string: url)!
        let URLRequest = NSMutableURLRequest(url: URL)

        URLRequest.cachePolicy = .reloadIgnoringCacheData

        let task = URLSession.shared.dataTask(with: URLRequest as URLRequest) { data, response, error in
            if error != nil {
                completionHandler?(error as NSError?, nil)
            }

            if data != nil {
                do {

                    if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary {
                        print(json)
                        completionHandler?(nil, json as NSDictionary?)
                    }
                } catch {
                    print("json exception: \(error)")
                    let err = NSError(domain: "com.whalerock.wkeyboard.networkAPI.fetchFailed", code: 0001, userInfo: nil)
                    completionHandler?(err, nil)
                }
            }
        }

        return task
    }




    // MARK: Additional Helpers

    fileprivate func customError(_ domain: String = "com.whalerock.keyboard.api", code: Int, description:String) -> NSError {

        let invalidResponse = WKeyboard.api.config?.value(forKeyPath: "configurations.notifications.invalidResponse") as? String ?? "Can not parse response to NSDictionary"

        let userInfo: [NSObject : AnyObject] =
            [
                NSLocalizedDescriptionKey as NSObject :  invalidResponse as AnyObject
            ]
        return NSError(domain: domain, code: code, userInfo: userInfo)
    }

    /**
     WRI custom logger which provides ability to enable/disable logging per class basis. Makes for cleaner debug console when needed.
     - parameter type:    See WRILoggerType
     - parameter message: Message you want to log
     */
    fileprivate func log(_ type: WRILoggerType, message:String) {
        guard self.loggingEnabled else {
            return
        }
        WRILogger.log(#file, type: type, message: message)
    }
}


//
//  Favorites.swift
//  Blitzmoji
//
//  Created by Sam Phomsopha on 7/15/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation

class Favorites {
    
    let defaults = UserDefaults.standard
    let userFavoritesKey = "usersFavorites"
    //private let favorites = [String: [String: [String: WKAsset]]]()
    
    func add(type: String, category: String, asset: WKAsset) -> Favorites {
        return addAsset(type: type, category: category, asset: asset)
    }
    
    func add(asset: WKAsset) -> Favorites{
        return addAsset(type: asset.type, category: asset.category, asset: asset)
    }
    
    func remove(asset: WKAsset) {
        let key = self.getKeyName(type: asset.type, category: asset.category)
        
        if let values = defaults.object(forKey: key) as? [[String: AnyObject]] {
                var mutableValues = cloneFavoritesValues(copyFrom: values)
                
                let dictValue = asset.dictionaryValue()
                var index = 0
                for i in 0..<mutableValues.count {
                    if NSDictionary(dictionary: mutableValues[i]).isEqual(to: dictValue) {
                        index = i
                        break
                    }
                }
                mutableValues.remove(at: index)
                defaults.set(mutableValues, forKey: key)
                defaults.synchronize()
                print("remove:defaults1: \(defaults.object(forKey: key))")
        }
    }
    
    func getAtIndex(type: String, category: String, index: Int) -> WKAsset? {
        let key = self.getKeyName(type: type, category: category)
        if let values = defaults.object(forKey: key) as? NSMutableArray {
            if let assetValues = values[index] as? NSDictionary {
                return WKAsset(json: assetValues)
            }
        }
        return nil
    }
    
    func getAll(type: String, category: String) -> [WKAsset]? {
        let key = self.getKeyName(type: type, category: category)
        
        print(defaults.object(forKey: key) ?? "no defaults for: \(key)")
        
        var favorites:[WKAsset]?
        
        if let values = defaults.object(forKey: key) as? [[String: AnyObject]] {
            print("assetValue: \(values)")
            favorites = [WKAsset]()
            for assetValues in values {
                print("assetValue: \(assetValues)")
                favorites?.append(WKAsset(json: assetValues as NSDictionary?)!)
            }
        }
        print(favorites ?? "no favorites")
        return favorites
    }
    
    func removeAll(type: String, category: String) {
        let key = self.getKeyName(type: type, category: category)
        defaults.removeObject(forKey: key)
        defaults.synchronize()
    }
    
    private func addAsset(type: String, category: String, asset: WKAsset) -> Favorites {
        let key = getKeyName(type: type, category: category)
        
        if let values = defaults.object(forKey: key) as? [[String: AnyObject]] {
            print("add::Values: \(values)")
            var mutableValues = cloneFavoritesValues(copyFrom: values)
            for existingAsset in mutableValues {
                if NSDictionary(dictionary: existingAsset).isEqual(to: asset.dictionaryValue()) {
                    return self
                }
            }
            mutableValues.append(asset.dictionaryValue() as [String : AnyObject])
            
            defaults.set(mutableValues, forKey: key)
            defaults.synchronize()
            print("setdefaults1: \(defaults.object(forKey: key))")
            
        } else {
            var values = [[String: AnyObject]]()
            values.append(asset.dictionaryValue() as [String : AnyObject])
            defaults.set(values, forKey: key)
            defaults.synchronize()
            
            print("setdefaults2: \(defaults.object(forKey: key))")
            
        }
        
        return self
    }
    
    private func getKeyName(type: String, category: String) -> String {
        return self.userFavoritesKey + "-" + type + "-" + category
    }
    
    private func cloneFavoritesValues(copyFrom: [[String: AnyObject]]) -> [[String: AnyObject]] {
        var mutableValues = [[String: AnyObject]]()
        for i in 0..<copyFrom.count {
            let item = copyFrom[i]
            var copy = [String: AnyObject]()
            for (k, v) in item {
                copy[k] = v
            }
            mutableValues.append(copy)
        }
        return mutableValues
    }
}

extension WKAsset {
    
    func dictionaryValue () -> [String: Any] {
        var dict = [String: Any]()
        
        guard self.id != nil,
                self.type != nil,
                self.pack != nil,
                self.title != nil,
                self.category != nil,
                self.tracking != nil,
                self.assetUrl != nil,
                self.position != nil,
                self.keywords != nil,
                self.tones != nil else {
                    print("invalid WKAsset!!!!!")
                    return dict
        }
        
        dict = [
            "id": self.id!,
            "type": self.type!,
            "pack": self.pack!,
            "title": self.title!,
            "category": self.category!,
            "tracking": self.tracking!,
            "asset_url": self.assetUrl!,
            "position": self.position!,
            "keywords": self.keywords!,
            "tones": self.tones! 
        ]
        
        return dict
    }
    
}

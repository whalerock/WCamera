//
//  AssetInputManager.swift
//  WCamera
//
//  Created by David Hoofnagle on 8/2/17.
//  Copyright © 2017 Whalerock. All rights reserved.
//

import UIKit
import WKeyboard

protocol AssetInputManagerDelegate {
    
    func didSelectAsset()
    
}

class AssetInputManager {

    static let shared = AssetInputManager()
    
    var delegate: AssetInputManagerDelegate?
    
    func displayAssetInput() {
        
    }
    
}

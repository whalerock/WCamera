//
//  MainViewEnums.swift
//  Kimoji
//
//  Created by aramik on 4/22/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation

public extension UIDevice {
    
    var iPhone: Bool {
        return UIDevice().userInterfaceIdiom == .phone
    }
    
    enum ScreenType: String {
        case iPhone4
        case iPhone5
        case iPhone6
        case iPhone6Plus
        case Unknown
    }
    var screenType: ScreenType {
        guard iPhone else { return .Unknown}
        switch UIScreen.main.nativeBounds.height {
        case 960:
            return .iPhone4
        case 1136:
            return .iPhone5
        case 1334:
            return .iPhone6
        case 1920:
            return .iPhone6Plus
        default:
            return .Unknown
        }
    }
    
}

public var isPortrait: Bool {
get {
    if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
        return true
    } else {
        return false
    }
}
}

public enum MainViewState {
    case preload
    case loading
    case emoji
    case inlineKeyboard
    case downloadAvailable
    case downloadingContent
    case fullAccessRequired
    case connectionRequired
    case configure
    case favoriteDefault
    case favorite
    
    var preferredKeyboardHeight: CGFloat {
        switch self {
        case .emoji:
            if isPortrait {
                return 260
            } else {
                return 187
            }
            
        case .inlineKeyboard:
            if isPortrait {
                return 280
            } else {
                return 197
            }
            
        default:
            if isPortrait {
                return 260
            } else {
                return 187
            }
        }
    }
}

public enum MainViewContext {
    case fullAccessRequired
    case loading
    case connectionRequired
    case downloadingContent
    case defaultFavorites
}

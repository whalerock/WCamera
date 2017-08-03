//
//  WRoute.swift
//
//  Created by sam phomsopha on 6/25/16.
//  Copyright © 2016 sam phomsopha. All rights reserved.
//

import Foundation

public struct WRoute {
    let path: String!
    let storyBoard: String?
    let routeClass: String?
    let indentifier: String?
    let handler: String?
    let presentationStyle: String?
    var url:URL!
    
    public init(storyBoard: String?, path: String?, indentifier: String?, routeClass: String?, handler: String?, presentationStyle: String? = nil) {
        if let _storyBoard = storyBoard {
            self.storyBoard = _storyBoard
        } else {
            self.storyBoard = nil
        }
        
        if let _path = path {
            self.path = _path
        } else {
            self.path = nil
        }
        
        if let _routeClass = routeClass {
            self.routeClass = _routeClass
        } else {
            self.routeClass = nil
        }
        
        if let _ident = indentifier {
            self.indentifier = _ident
        } else {
            self.indentifier = nil
        }
        
        if let _handler = handler {
            self.handler = _handler
        } else {
            self.handler = nil
        }
        
        if let _presentationStyle = presentationStyle {
            self.presentationStyle = _presentationStyle
        } else {
            self.presentationStyle = nil
        }
    }
}

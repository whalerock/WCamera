//
//  ALRadialMenuButton.swift
//  ALRadialMenu
//
//  Created by Alex Littlejohn on 2015/04/26.
//  Copyright (c) 2015 zero. All rights reserved.
//

import UIKit

public typealias ALRadialMenuButtonAction = () -> Void

open class ALRadialMenuButton: UIButton {
    open var pointInView:CGPoint?
    
    open var action: ALRadialMenuButtonAction? {
        didSet {
            configureAction()
        }
    }
    
    fileprivate func configureAction() {
        addTarget(self, action: #selector(performAction), for: UIControlEvents.touchUpInside)
    }
    
    internal func performAction() {
        if let a = action {
            a()
        }
    }
}

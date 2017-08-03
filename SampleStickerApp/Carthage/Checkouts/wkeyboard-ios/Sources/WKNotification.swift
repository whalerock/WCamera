//
//  WKNotificationConstants.swift
//  Kimoji
//
//  Created by aramik on 4/22/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation

/// Use this class to view available NSNotificationCenter observers through the app.

open class WKNotifications {
    open static let HeaderViewDisplayStatus = "com.whalerock.keyboard.headerView.displayStatus"
    open static let HeaderViewCopiedNotification = "com.whalerock.keyboard.headerView.copiedNotification"
    open static let ToolBarDidChangeType = "com.whalerock.keyboard.toolbarView.didChangeType"

    open static let TextDocumentProxyInsertText = "com.whalerock.keyboard.tdp.insertText"
    open static let TextDocumentProxyDeleteBackwards = "com.whalerock.keyboard.tdp.deleteBackwords"

}


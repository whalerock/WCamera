//
//  DownloadViewController.swift
//  Kimoji
//
//  Created by aramik on 4/23/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit

open class DownloadViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet public weak var progressView: CircularProgressView!
    @IBOutlet public weak var assetPreview: UIImageView!
    @IBOutlet public weak var statusLabel: UILabel!
    
    // MARK: Public Initializers
    open var previousTime: TimeInterval = 0
    open var slowConnectionTimer: Timer?
    
    // MARK: Private Initializers
    fileprivate var loggingEnabled: Bool = true
    
    // MARK: Override Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.log(.log, message: "Loaded")
        
        //self.view.setNeedsLayout()
        //self.view.layoutIfNeeded()

        self.statusLabel.text = WKeyboard.api.config?.value(forKeyPath: "configurations.notifications.preparingToDownload") as? String ?? "PREPARING TO DOWNLOAD CONTENT"
        
        self.progressView.backgroundColor = GlobalColors.circularProgressBackgroundColor
        self.progressView.trackTintColor = GlobalColors.circularTrackTintColor
        self.progressView.progressTintColor = GlobalColors.circularProgressTintColor
        
        self.progressView.progress = 0.0
        self.assetPreview.layer.cornerRadius = self.assetPreview.frame.width / 2
        self.assetPreview.layer.masksToBounds = true
        
        self.slowConnectionTimer = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(slowConnection), userInfo: nil, repeats: false)
    }
    
    open func slowConnection() {
        if self.statusLabel.text != "" {
            let statusText = WKeyboard.api.config?.value(forKeyPath: "configurations.notifications.connectionTimedOut") as? String ?? "CONNECTION TIMED OUT. PLEASE CHECK YOUR CONNECTION SETTINGS. TRY CLOSING THE APP AND RE-OPENING."
            self.statusLabel.text = statusText
        }
        self.slowConnectionTimer?.invalidate()
        self.slowConnectionTimer = nil
    }
    
    open override func didReceiveMemoryWarning() {
        self.log(.warning, message: "Received Memory Warning")
    }
    
    deinit {
        self.log(.log, message: "Deinitialized")
    }
    
    // MARK: Lifecycle
    
    // MARK: Layouts
    
    // MARK: User Interactions
    
    // MARK: Additional Helpers
    
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

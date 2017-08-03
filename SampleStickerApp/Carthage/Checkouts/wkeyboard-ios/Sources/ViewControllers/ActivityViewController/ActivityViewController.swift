//
//  ActivityViewController.swift
//  Kimoji
//
//  Created by aramik on 4/23/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit

protocol ActivityViewControllerDelegate {
    func didPressFullAccessRequiredHowToInstall(_ sender: AnyObject?)
}



open class ActivityViewController: UIViewController {
    
    // MARK: Public Initializers
    open var downloadViewController: DownloadViewController!
    open var fullAccessRequiredViewController: FullAccessRequiredViewController!
    
    var delegate: ActivityViewControllerDelegate?
    
    // MARK: Private Initializers
    fileprivate var loggingEnabled: Bool = false
    open var attachedViewStoryboardID: String!
    
    // MARK: Override Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.log(.log, message: "Loaded.")
    }
    
    open override func didReceiveMemoryWarning() {
        self.log(.warning, message: "Received Memory Warning")
    }
    
    deinit {
        self.log(.log, message: "Deinitialized.")
    }
    
    // MARK: Lifecycle
    
    
    // MARK: Layouts
    
    open func setAttachedView(_ storyboardIdentifier:String) {
        if self.attachedViewStoryboardID != storyboardIdentifier {
            if let attachedView = self.view.viewWithTag(10001) {
                attachedView.removeFromSuperview()
                self.downloadViewController = nil
            }
            
            switch storyboardIdentifier {
                case "sb_DownloadViewController":
                    if let _downloadViewController = mainStoryboard().instantiateViewController(withIdentifier: storyboardIdentifier) as? DownloadViewController {
                        downloadViewController = _downloadViewController
                        self.addChildViewController(downloadViewController)
                        downloadViewController.view.frame = self.view.bounds
                        self.view.addSubview(downloadViewController.view)
                        self.downloadViewController.view.tag = 10001
                        self.attachedViewStoryboardID = storyboardIdentifier
                    }
                    
                case "sb_FullAccessRequiredViewController":
                    if let _fullAccessViewController = mainStoryboard().instantiateViewController(withIdentifier: storyboardIdentifier) as? FullAccessRequiredViewController {
                        fullAccessRequiredViewController = _fullAccessViewController
                        fullAccessRequiredViewController.delegate = self
                        self.addChildViewController(fullAccessRequiredViewController)
                        fullAccessRequiredViewController .view.frame = self.view.bounds
                        self.view.addSubview(fullAccessRequiredViewController .view)
                        self.fullAccessRequiredViewController .view.tag = 10001
                        self.attachedViewStoryboardID = storyboardIdentifier
                        
                        fullAccessRequiredViewController!.view.layer.borderWidth = 1.0
                        fullAccessRequiredViewController!.view.layer.borderColor = UIColor.red.cgColor
                        
                        self.view.setNeedsLayout()
                        self.view.layoutIfNeeded()
                    }
                    
                default:
                    self.downloadViewController = nil
                    let newVC = mainStoryboard().instantiateViewController(withIdentifier: storyboardIdentifier)
                    newVC.view.frame = self.view.bounds
                    newVC.view.tag = 10001
                    self.view.addSubview(newVC.view)
                    self.attachedViewStoryboardID = storyboardIdentifier
            }
            
        }
    }
    
    open func removeCurrentView() {
        if let attachedView = self.view.viewWithTag(10001) {
            attachedView.removeFromSuperview()
        }
        downloadViewController = nil
        fullAccessRequiredViewController = nil
    }
    
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

extension ActivityViewController: FullAccessRequiredViewControllerDelegate {
    
    func didPressHowToInstall(_ sender: AnyObject?) {
        delegate?.didPressFullAccessRequiredHowToInstall(sender)
    }
    
}

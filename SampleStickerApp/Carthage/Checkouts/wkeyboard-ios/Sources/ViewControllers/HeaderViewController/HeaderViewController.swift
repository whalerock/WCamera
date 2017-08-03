//
//  HeaderViewController.swift
//  Kimoji
//
//  Created by aramik on 4/22/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore

public protocol HeaderViewDelegate: class {
    func didTapMoreButton()
}

open class HeaderViewController: UIViewController {
    
    // MARK: Interface Builder Outlets
    @IBOutlet weak var brandTitle: UILabel?
    @IBOutlet weak var statusBarLabel: UILabel?
    @IBOutlet weak var statusBarTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusBarHeightConstraint: NSLayoutConstraint?
    @IBOutlet weak var containerAppButton: UIButton!
    
    // MARK: Public Initializers
    open weak var delegate: HeaderViewDelegate?
    open var highlightColor: String?
    
    // MARK: Private Initializers
    fileprivate var loggingEnabled: Bool = true
    fileprivate var didUpdateViewConstraints: Bool = false
    fileprivate let notificationCenter = NotificationCenter.default
    fileprivate weak var statusBarTimer: Timer!
    fileprivate var currentTypeTitle: String!
    open var notificationFader: Timer!
    
    // MARK: Computed Properties
    fileprivate var isStatusBarVisible: Bool {
        get {
            if statusBarLabel?.valueForConstraint("top") == 0 || statusBarLabel?.valueForConstraint("top") == 5 {
                return true
            }
            return false
        }
    }
    
    // MARK: Override Lifecycle
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        brandTitle?.text = WKConfig.sharedInstance.keyboardName
        // Calling these manually to make sure view layout is set and doesn't get pulled into any animation blocks while loading; Like the Keyboard's height being animated at load.
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        self.initNotifications()
        self.hideStatusBar(false)
        
        self.putMoreButtonTitle()
    
    }
    
    func checkContainerAppButtonStatus() {
        guard let config = WKeyboard.api.config?.value(forKey: "configurations") else {
            return
        }
        
        if let isContainerAppButtonEnabled = (config as AnyObject).value(forKeyPath: "keyboard.merch_button_enabled") as? Bool {
            if isContainerAppButtonEnabled {
                self.containerAppButton.isHidden = false
            } else {
                self.containerAppButton.isHidden = true
            }
        }
    }
  
  func putMoreButtonTitle() {
    guard let config = WKeyboard.api.config?.value(forKey: "configurations") else {
      return
    }
    
    if let containerAppButtonTitle = (config as AnyObject).value(forKeyPath: "keyboard.container_app_button_text") as? String {
      if containerAppButtonTitle == "" {
        self.containerAppButton.setTitle("•••", for: .normal)
      } else {
        DispatchQueue.main.async {
          self.containerAppButton.setTitle(containerAppButtonTitle, for: .normal)
        }
      }
    }
  }
  
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.checkForUninstalledPacks()
      self.putMoreButtonTitle()
    }
  
    /**
     Check for Uninstalled Packs to display message
   
     - TODO: Add this back in
     */
    open func checkForUninstalledPacks() {
        
//        guard self.notificationFader == nil else {
//            return
//        }
//        if let featuredPack = WKAPI.manager.config?.valueForKeyPath("keyboard.notification_flag_bundle_identifier") as? String {
//           
//            if featuredPack != "" {
//                if WRIStoreKit.manager.didPurchase(featuredPack) {
//                    
//                    self.containerAppButton.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
//                } else {
//                    if let containerAppButtonTitle = WKAPI.manager.config?.valueForKeyPath("keyboard.container_app_button_text") as? String {
//                        if containerAppButtonTitle == "" {
//                            self.containerAppButton.setTitle("•••", forState: .Normal)
//                        } else {
//                            self.containerAppButton.setTitle(containerAppButtonTitle, forState: .Normal)
//                        }
//                        
//                    }
//                    
//                    if let containerAppButtonColor = WKAPI.manager.config?.valueForKeyPath("keyboard.container_app_highlight_color") as? String {
//                        self.highlightColor = containerAppButtonColor
//                    }
//                    self.notificationFader =  NSTimer.scheduledTimerWithTimeInterval(1.1, target: self, selector: #selector(self.fadeNotification), userInfo: nil, repeats: true)
//                    
//                }
//            }
//        }
    }
    
    open func stopNotification() {
        guard self.notificationFader != nil else {
            return
        }
        self.notificationFader.invalidate()
        self.notificationFader = nil
    }
    
    open func fadeNotification() {
     
        
        
        
        
        UIView.transition(with: self.containerAppButton, duration: 0.5, options: [UIViewAnimationOptions.transitionCrossDissolve,UIViewAnimationOptions.allowUserInteraction], animations: {
            if let color = self.highlightColor {
                  self.containerAppButton.titleLabel?.textColor =  UIColor(hex: color)
               
                self.containerAppButton.layer.shadowRadius = 2.0
                self.containerAppButton.layer.shadowOffset = CGSize.zero
                self.containerAppButton.layer.shadowOpacity = 0.3
                self.containerAppButton.layer.shadowColor = UIColor(hex: color).cgColor
            } else {
                 self.containerAppButton.titleLabel?.textColor = UIColor.blue
            }
            
            }, completion: { finished in
                UIView.transition(with: self.containerAppButton, duration: 0.5, options: [UIViewAnimationOptions.transitionCrossDissolve,UIViewAnimationOptions.allowUserInteraction], animations: {
                    self.containerAppButton.titleLabel?.textColor = UIColor.lightGray
                    self.containerAppButton.layer.shadowRadius = 0
                    self.containerAppButton.layer.shadowOffset = CGSize.zero
                    self.containerAppButton.layer.shadowOpacity = 0
                    self.containerAppButton.layer.shadowColor = UIColor.clear.cgColor
                    }, completion: { finished in
                        
                })
        })
        
       
    }
    
    deinit {
        notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        self.log(WRILoggerType.log, message: "Deinitialized")
    }
    
    open override func didReceiveMemoryWarning() {
        self.log(.warning, message: "Received Memory Warning")
    }
    
    
    // MARK: Lifecycle
    
    fileprivate func startStatusBarDisplayTimer() {
        if self.statusBarTimer != nil {
            self.statusBarTimer.invalidate()
            self.statusBarTimer = nil
        }
      
        self.statusBarTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(hideStatusBar(_:)), userInfo: nil, repeats: false)
    }
    
    fileprivate func stopStatusBarDisplayTimer() {
        guard self.statusBarTimer != nil else {
            return
        }
        self.statusBarTimer.invalidate()
        self.statusBarTimer = nil
    }
    
    fileprivate func updateStatusBar(_ type:HeaderViewStatusBarType, text:String, autoHide:Bool = true) {
        self.statusBarLabel?.setValueForConstraint("top", value: type.metrics.top, animated:true)
        self.statusBarLabel?.setValueForConstraint("height", value: type.metrics.height, animated:false)
        
//        if let copiedBackgroundImage = UIImage(named: "Copied") {
//            UIGraphicsBeginImageContext(self.statusBarLabel!.frame.size)
//            copiedBackgroundImage.drawInRect(self.statusBarLabel!.frame)
//            let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
//            UIGraphicsEndImageContext()
//            self.statusBarLabel?.backgroundColor = UIColor(patternImage:image)
//        } else {
//            self.statusBarLabel?.backgroundColor = type.style.backgroundColor
//        }
        
        self.statusBarLabel?.textColor = GlobalColors.statusBarLabelTextColor
        self.statusBarLabel?.backgroundColor = GlobalColors.statusBarLabelBackgroundColor
        self.statusBarLabel?.font = GlobalColors.statusBarLabelFont
        
        self.statusBarLabel?.layer.cornerRadius = type.style.borderRadius
        self.statusBarLabel?.layer.masksToBounds = true
        self.statusBarLabel?.text = text
        if autoHide {
            self.startStatusBarDisplayTimer()
        }
    }
    
    open func restoreTitle() {
        guard self.currentTypeTitle != nil else {
            return
        }
        self.brandTitle?.text = self.currentTypeTitle
    }
    
    
    // MARK: View Layouts
    
    @objc open func hideStatusBar(_ animated:Bool = true) {
        guard let statusBar = self.statusBarLabel else {
            self.log(.warning, message: "Attempted to hide status bar with a value of 'nil'")
            return
        }

        statusBar.setValueForConstraint("top", value: -statusBar.frame.height, animated:true)
        
    }
    
    fileprivate func showStatusBar(_ style:HeaderViewStatusBarType, text:String, autoHide:Bool = true) {
        guard self.isStatusBarVisible else {
            self.updateStatusBar(style, text: text, autoHide: autoHide)
            return
        }

        if self.statusBarLabel?.text == text {
        UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: UIViewAnimationOptions(), animations: { [weak self] in
            self?.statusBarLabel?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: UIViewAnimationOptions(), animations: { [weak self] in
                    self?.statusBarLabel?.transform = CGAffineTransform(scaleX: 1, y: 1)
                    }, completion: { _ in
                        
                })
        })
        }
        self.updateStatusBar(style, text: text, autoHide: autoHide)
    }
    
    
    // MARK: NSNotificationCenter and Handlers
    open func initNotifications() {
        notificationCenter.addObserver(self, selector: #selector(displayStatusNotificationHandler(_:)), name: NSNotification.Name(rawValue: WKNotifications.HeaderViewDisplayStatus), object: nil)

        notificationCenter.addObserver(self, selector: #selector(didChangeTypeNotificationHandler(_:)), name: NSNotification.Name(rawValue: WKNotifications.ToolBarDidChangeType), object: nil)

        notificationCenter.addObserver(self, selector: #selector(displayCopiedNotification(_:)), name: NSNotification.Name(rawValue: WKNotifications.HeaderViewCopiedNotification), object: nil)

    }
    
    open func didChangeTypeNotificationHandler(_ sender: Notification) {

    }
    
    open func displayCopiedNotification(_ sender: Notification) {
        let displayCopied = WKeyboard.api.config?.value(forKeyPath: "configurations.notifications.displayCopied") as? String ?? "COPIED!"
        self.showStatusBar(.Notification, text: displayCopied, autoHide: true)
    }
    
    open func displayStatusNotificationHandler(_ sender:Notification) {
//        let notification = HeaderViewNotification.init(userInfo: (sender as NSNotification).userInfo! as [NSObject : AnyObject])
        if let userInfo = sender.userInfo as [AnyHashable : Any]? {
            let notification = HeaderViewNotification.init(userInfo: userInfo)
            self.showStatusBar(notification.type, text: notification.text, autoHide: notification.autoHide)
        }
    }
    
    
    // MARK: User Interaction
    
    /**
     Directs user to Container/Host App
     - parameter sender: Button that was tapped
     */
    @IBAction func openContainerApp(_ sender:UIButton) {
        self.delegate?.didTapMoreButton()
    }
    
    
    
    // MARK: Additional Helpers
    
    /**
     Used to animate view constraints without having to explicitly set IBOutlets as well as having consistent animation block parameters.  Also prevents numerious duplicates of animation block for a cleaner, more maintainable code base.
     - parameter view:       View of constraint you want to update
     - parameter identifier: Constraint Identifier which must be set through Interface Builder
     - parameter constant:   Updated position value
     - parameter duration:   Duration of animation; or set to '0' for none; default value already set
     */
    fileprivate func updateConstraint(_ view:UIView?, identifier: String, constant:CGFloat, animated:Bool, duration:TimeInterval = 0.5) {
        guard view != nil else {
            self.log(.warning, message: "Attempted to update a constraint of an view that is 'nil'")
            return
        }
        
        view?.setValueForConstraint(identifier, value: constant, animated:true)
        
       
        
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



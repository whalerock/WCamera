//
//  ToolBarViewController.swift
//  Kimoji
//
//  Created by aramik on 4/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import UIKit
import WUtilities
import WAnalytics

enum TAG: Int {
    case SWITCH_KEYBOARD_TAG = 100
    case INLINE_KEYBOARD_TAG = 101
    case BACKSPACE_KEYBOARD_TAG = 102
    case FAVORITES_KEYBOARD_TAG = 103
    
    case TOOLBAR_FIXED_SPACE_TAG = 999
    case TOOLBAR_FLEXIBLE_SPACE_TAG = 1000
}

public protocol ToolbarViewControllerDelegate {
    func toolBarDidChangeType(sender: UIButton)
}

open class ToolBarViewController: UIViewController {
  
    // MARK: InterfaceBuilder Outlets
    @IBOutlet open var toolBar: UIToolbar!
    var tabButtons = [UIButton]()
  
    // MARK: Public Initializers
    open var selectedTabIndicator: UIImageView?
    open var delegate: ToolbarViewControllerDelegate?
    
    open var types: [WKType]! {
        didSet {
            setupTabs()
            setState(.default)
            //setSelectedIndex(0)
        }
    }
  
    // MARK: Private Initializers
    fileprivate var loggingEnabled: Bool = true
    open var customItems: [UIBarButtonItem]!
    open var previousSelectedTypeTag = -1
    open var selectedTypeTag: Int! = -1 {
        didSet {
            print("DIDSET: selectedTypeTag:: \(selectedTypeTag) previousSelectedTypeTag: \(previousSelectedTypeTag)")
            previousSelectedTypeTag = selectedTypeTag
        }
    }
    fileprivate var selectedButtonRef: UIButton!

    // Required UIBarButton Items
    fileprivate var switchKeyboardItem: UIBarButtonItem?
    fileprivate var favoritesItem: UIBarButtonItem?
    fileprivate var inlineKeyboardItem: UIBarButtonItem?
    fileprivate var backspaceItem: UIBarButtonItem?
    fileprivate var flexableSpacer: UIBarButtonItem!
    fileprivate var fixedSpacer: UIBarButtonItem!
    //let kFixedSpacerWidth: CGFloat = 20.0
  
    // MARK: Computed Properties
    fileprivate var state: ToolBarState! {
        didSet {
          self.log(.log, message: "Switched state to \(self.state)")
        }
    }
  
    // MARK: Override Lifecycle
    open override func viewDidLoad() {
        super.viewDidLoad()

        toolBar.barTintColor = WKConfig.sharedInstance.toolbarBackgroundColor
        toolBar.tintColor = WKConfig.sharedInstance.toolbarTintColor

        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()

        self.toolBar.clipsToBounds = true
        customItems = [UIBarButtonItem]()
        // FlexableSpacer should come between each item, except for the negativeSpacer, to automatically adjust the width between them.
        flexableSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        flexableSpacer.tag = TAG.TOOLBAR_FLEXIBLE_SPACE_TAG.rawValue
        if !WKConfig.sharedInstance.isImessageExtension {
            self.initDefaultToolBarItems()
        }
        setState(.fullAccessRequired)
    
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if WKConfig.sharedInstance.wantsToolbarSelectedIndicator && selectedTabIndicator == nil {
            if let image = UIImage(named: "selectedIndicator") {
                selectedTabIndicator = UIImageView(image: image)
                self.view.addSubview(selectedTabIndicator!)
                selectedTabIndicator!.frame = CGRect(x: -100, y: 28.5, width: 37.5, height: 7.5)
                selectedTabIndicator!.translatesAutoresizingMaskIntoConstraints = false
                selectedTabIndicator!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0.0).isActive = true
                self.view.setNeedsLayout()
                self.view.layoutIfNeeded()
                selectedTabIndicator!.isHidden = true
                print("selectedFrame:", selectedTabIndicator!)
            }
        }
    }
    
    open func forceSelectItem(withTag tag: Int) {
        var previouslySelectedButton: UIButton?
        for button in tabButtons {
            button.isSelected = false
            if button.tag == tag {
                previouslySelectedButton = button
            }
        }
        guard previouslySelectedButton != nil else {
            return
        }
        previouslySelectedButton!.isSelected = true
        selectedButtonRef = previouslySelectedButton!
        if previouslySelectedButton!.tag < 100 {
            selectedTypeTag = tag
            if customItems != nil {
                for i in 0..<self.customItems!.count {
                    if self.selectedTypeTag != self.customItems![i].tag {
                        (self.customItems![i].customView)?.tintColor = WKConfig.sharedInstance.toolbarTintColor
                    }
                }
            }
            previouslySelectedButton!.tintColor = WKConfig.sharedInstance.toolbarSelectedTintColor
        }
    }

    open override func didReceiveMemoryWarning() {
        self.log(.warning, message: "Received Memory Warning")
    }

    deinit {
        self.log(.log, message: "Deinitialized")
    }
    
    public func willRotateDevice() {
        selectedTabIndicator?.isHidden = true
    }
    
    public func didRotateDevice() {
        delay(0.4) {
            self.updateSelectorPosition()
        }
    }
    
    // MARK: Lifecycle

    open func setSelectedIndex(_ index:Int) {
        WKManager.sharedInstance.selectedIndex = index
        if /*self.selectedButtonRef == nil &&*/ self.customItems.count > 0 {
            let buttonItem = self.customItems[index]
            if let buttonRef = buttonItem.customView as? UIButton {
                self.selectedButtonRef = buttonRef
                self.selectItem(buttonRef)
            }
        }
        delay(0.1) {
            self.updateSelectorPosition()
        }
    }
  
    // MARK: Layouts
  
    open func setState(_ state:ToolBarState) {
        self.log(.log, message: "requesting state: \(state)")
        self.toolBar.setItems([], animated: false)

        switch state {
            case .initial:
                self.toolBar.setItems([], animated: false)
            case .fullAccessRequired:
                if !WKConfig.sharedInstance.isImessageExtension {
                    self.toolBar.setItems([
                        //fixedSpacer,
                        switchKeyboardItem!,
                        flexableSpacer!,
                        inlineKeyboardItem!,
                        //fixedSpacer
                        ], animated: false)
                } else {
                    self.toolBar.setItems([], animated: false)
                }
            case .default:
                var tempArray = [UIBarButtonItem]()

                if !WKConfig.sharedInstance.isImessageExtension {
                    tempArray.append(switchKeyboardItem!)
                    tempArray.append(flexableSpacer)

                    if WKConfig.sharedInstance.wantsFavoritesEnabled {
                        tempArray.append(favoritesItem!)
                        tempArray.append(flexableSpacer)
                    }
                    tempArray.append(contentsOf: self.customItems)
                    tempArray.append(inlineKeyboardItem!)
                    tempArray.append(flexableSpacer)
                    tempArray.append(backspaceItem!)
                } else {
                    tempArray.append(self.flexableSpacer)
                    tempArray.append(contentsOf: self.customItems)
                }
                self.toolBar.setItems(tempArray, animated: false)
                //self.setSelectedIndex(0)
        }

        self.state = state
    }
  
    // MARK: ToolBarItem Setups
  
    fileprivate func initDefaultToolBarItems() {
        // SwitchKeyboardItem
        switchKeyboardItem = self.createCustomBarButtonItem("NextKeyboard", selectedImageName: nil, tag: TAG.SWITCH_KEYBOARD_TAG.rawValue, type: nil)
        
        // InlineKeyboardItem
        inlineKeyboardItem = self.createCustomBarButtonItem("InlineKeyboard", selectedImageName: nil, tag: TAG.INLINE_KEYBOARD_TAG.rawValue, type: nil)
        
        // BackspaceItem
        backspaceItem = self.createCustomBarButtonItem("KeyboardBackspace", selectedImageName: nil, tag: TAG.BACKSPACE_KEYBOARD_TAG.rawValue, type: nil)

        if WKConfig.sharedInstance.wantsFavoritesEnabled {
            let type = WKType()
            type.id = "favorite"
            type.title = "Favorites"
            favoritesItem = createCustomBarButtonItem("Favorites", selectedImageName: "ActiveFavorites", tag: TAG.FAVORITES_KEYBOARD_TAG.rawValue, type: type)
        }
    }
  
    fileprivate func createCustomBarButtonItem(_ imageName:String, selectedImageName: String?, tag: Int, type: WKType?) -> UIBarButtonItem {
        
        let customButton = ToolBarIconButton(type: .custom)
        customButton.frame = CGRect(x: 0, y: 0, width: 54, height: 54)
        
        var image = UIImage(named: imageName)
        if WKConfig.sharedInstance.wantsToolbarItemsAlwaysTemplate {
            image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        }
        customButton.setImage(image, for: UIControlState.normal)
        
        if selectedImageName != nil {
            var selectedImage = UIImage(named: selectedImageName!)
            if WKConfig.sharedInstance.wantsToolbarItemsAlwaysTemplate {
                selectedImage = UIImage(named: selectedImageName!)?.withRenderingMode(.alwaysTemplate)
            }
            customButton.setImage(selectedImage, for: UIControlState.highlighted)
            customButton.setImage(selectedImage, for: UIControlState.selected)
        }
        
        customButton.imageView?.contentMode = .scaleAspectFit
        customButton.addTarget(self, action: #selector(selectItem(_:)), for: .touchUpInside)
        customButton.tag = tag
        if type != nil {
            customButton.type = type!
        }
        
        tabButtons.append(customButton)

        let customBarButtonItem = UIBarButtonItem(customView: customButton)
        customBarButtonItem.tag = tag
        
        return customBarButtonItem
    }
    
    fileprivate func setupTabs() {
        self.customItems.removeAll()

        for (index, type) in self.types.enumerated() {
            if (type.assetUrl?.contains(".gif"))! ||
                (type.title?.lowercased().contains("gif"))!
            {

                if WKConfig.sharedInstance.wantsToolbarImagesFromCMS {
                    let gifTab = ToolBarGIFItem(url: type.assetUrl!, tag: index, action: #selector(self.selectItem(_:)), target: self)
                    gifTab.customButton.type = type
                    self.customItems.append(gifTab)
                    tabButtons.append(gifTab.customButton)
                } else {
                    let gifBarButtonItem = createCustomBarButtonItem("GIF", selectedImageName: "ActiveGIF", tag: index, type: type)
                    self.customItems.append(gifBarButtonItem)
                }

            } else {

                if WKConfig.sharedInstance.wantsToolbarImagesFromCMS {
                    if let emojiTab = ToolBarIconItem(url: type.assetUrl!, tag: index, action: #selector(self.selectItem(_:)), target: self) {
                        emojiTab.customButton.type = type
                        self.customItems.append(emojiTab)
                        tabButtons.append(emojiTab.customButton)
                    }
                } else {
                    let emojiBarButtonItem = createCustomBarButtonItem("Stickers", selectedImageName: "ActiveStickers", tag: index, type: type)
                    self.customItems.append(emojiBarButtonItem)
                }

            }
            self.customItems.append(self.flexableSpacer)
        }
    }
  
    open func updateSelectorPosition() {
        guard self.selectedButtonRef != nil, self.selectedTabIndicator != nil else {
            return
        }
        print("buttonRefTag:: \(self.selectedButtonRef.tag)")
        if let sender = self.selectedButtonRef {
            if sender.tag < 100 && WKConfig.sharedInstance.wantsToolbarSelectedIndicator {
                print("selectedTabFRAME: ", self.selectedTabIndicator!.frame)
                print("centerx: ", sender.center.x)
                
                self.selectedTabIndicator!.isHidden = false
                self.selectedTabIndicator!.center.x = sender.center.x
                //self.view.bringSubview(toFront: self.selectedTabIndicator!)
                print("selectedTabFRAME: ", self.selectedTabIndicator!.frame)
                selectedTabIndicator!.setNeedsLayout()
                selectedTabIndicator!.setNeedsDisplay()
            }
        }
    }
  
    // MARK: User Interactions
  
    open func selectItem(_ sender:UIButton) {

        print("senderTag: \(sender.tag)")
        guard self.selectedTypeTag > 100 || self.selectedTypeTag != sender.tag else {
            self.log(.log, message: "Already selected.")
            delegate?.toolBarDidChangeType(sender: sender)
            return
        }

        for button in tabButtons {
            button.isSelected = false
        }
        sender.isSelected = true
        
        if sender.tag < 100 {
            self.selectedButtonRef = sender
            selectedTypeTag = sender.tag
            if customItems != nil {
                for i in 0..<self.customItems!.count {
                    if self.selectedTypeTag != self.customItems![i].tag {
                        (self.customItems![i].customView)?.tintColor = WKConfig.sharedInstance.toolbarTintColor
                    }
                }
            }
            sender.tintColor = WKConfig.sharedInstance.toolbarSelectedTintColor
            self.updateSelectorPosition()
        }

        //    NotificationCenter.default.post(name: Notification.Name(rawValue: WKNotifications.ToolBarDidChangeType), object: sender)
        delegate?.toolBarDidChangeType(sender: sender)
    }
  
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
    
    public func setSelectedType(typeName:String) {
        if let toType = self.findItemByTypeName(typeName: typeName) {
            selectItem(toType)
        }
    }
    
    public func getCurrentType() -> WKType? {
        if let currentType = self.findTypeByTag(tag: self.selectedTypeTag) {
            return currentType
        }
        return nil
    }

    public func findTypeByName(name:String) -> WKType? {
        for type in self.types {
            if type.title?.lowercased() == name.lowercased() {
                return type
            }
        }
        return nil
    }
    
    private func findTypeByTag(tag:Int) -> WKType? {
        for item in self.customItems {
            if item.tag == (tag - 100) {
                if let brandItem = item.customView as? ToolBarIconButton {
                    return brandItem.type
                }
            }
        }
        return nil
    }
    
    private func findItemByTypeName(typeName:String) -> UIButton? {
        for item in self.customItems {
            if let brandItem = item.customView as? ToolBarIconButton {
                if brandItem.type?.title?.lowercased() == typeName.lowercased() {
                    return brandItem
                }
            }
        }
        return nil
    }
}

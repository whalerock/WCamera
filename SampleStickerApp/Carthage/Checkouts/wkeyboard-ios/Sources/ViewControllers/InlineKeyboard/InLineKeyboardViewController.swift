//
//  KeyboardViewController.swift
//  Keyboard
//
//  Created by Alexei Baboulevitch on 6/9/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit
import AudioToolbox
import WAnalytics

let metrics: [String:Double] = [
    "topBanner": 30
]
func metric(_ name: String) -> CGFloat { return CGFloat(metrics[name]!) }

// TODO: move this somewhere else and localize
let kAutoCapitalization = "kAutoCapitalization"
let kPeriodShortcut = "kPeriodShortcut"
let kKeyboardClicks = "kKeyboardClicks"
let kSmallLowercase = "kSmallLowercase"

public protocol InlineKeyboardDelegate: class {
    func didPressKey(_ key:String)
    func didPressBackspace()
    func didPressShare()
    func shouldDismissKeyboard()
}

open class InlineKeyboardViewController: UIViewController {
    
    @IBInspectable open var appMode: Bool = false
    open var mainTintColor: UIColor = UIColor.lightGray
    let backspaceDelay: TimeInterval = 0.5
    let backspaceRepeat: TimeInterval = 0.07
    weak open var parentVC: MainViewController?
    var keyboard: Keyboard!
    var forwardingView: ForwardingView!
    var layout: KeyboardLayout?
    var heightConstraint: NSLayoutConstraint?
    open weak var delegate: InlineKeyboardDelegate?
    var bannerView: UIView?
    var settingsView: ExtraView?
    
    var currentInterfaceOrientation: UIInterfaceOrientation! {
        get {
            if UIScreen.main.bounds.width < UIScreen.main.bounds.height {
                return UIInterfaceOrientation.portrait
            } else {
                return UIInterfaceOrientation.landscapeLeft
            }
        }
    }
    
    var currentMode: Int {
        didSet {
            if oldValue != currentMode {
                setMode(currentMode)
            }
        }
    }
    
    var backspaceActive: Bool {
        get {
            return (backspaceDelayTimer != nil) || (backspaceRepeatTimer != nil)
        }
    }
    var backspaceDelayTimer: Timer?
    var backspaceRepeatTimer: Timer?
    
    enum AutoPeriodState {
        case noSpace
        case firstSpace
    }
    
    var autoPeriodState: AutoPeriodState = .noSpace
    var lastCharCountInBeforeContext: Int = 0
    
    var shiftState: ShiftState {
        didSet {
            switch shiftState {
            case .disabled:
                self.updateKeyCaps(false)
            case .enabled:
                self.updateKeyCaps(true)
            case .locked:
                self.updateKeyCaps(true)
            }
        }
    }
    
    // state tracking during shift tap
    var shiftWasMultitapped: Bool = false
    var shiftStartingState: ShiftState?
    
    open var keyboardBounds: CGRect {
        get {
            guard forwardingView != nil else {
                return CGRect(x: 0, y: 0, width: 0, height: 0)
            }
            return forwardingView!.bounds
        }
    }
    
    open fileprivate(set) var keyboardHeight: CGFloat {
        get {
            if let constraint = self.heightConstraint {
                return constraint.constant
            }
            else {
                return 0
            }
        }
        set {
            self.setHeight(newValue)
        }
    }
    
    // TODO: why does the app crash if this isn't here?
    convenience init() {
        self.init(nibName: nil, bundle: nil)
    }
    
    
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        UserDefaults.standard.register(defaults: [
            kAutoCapitalization: true,
            kPeriodShortcut: true,
            kKeyboardClicks: true,
            kSmallLowercase: true
            ])
        
        
        //self.keyboard = defaultKeyboard(self.appMode)
        
        self.shiftState = .disabled
        self.currentMode = 0
        
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.forwardingView = ForwardingView(frame: CGRect.zero)
        self.view.addSubview(self.forwardingView)
        
        NotificationCenter.default.addObserver(self, selector: #selector(InlineKeyboardViewController.defaultsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        
        
    }
    
    
    
    required convenience public init?(coder: NSCoder) {
        self.init()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        
    }
    
    deinit {
        
        print("deinit called from inlinekeyboard")
        backspaceDelayTimer?.invalidate()
        backspaceRepeatTimer?.invalidate()
        
        if !self.appMode {
        self.keyboard = nil
        self.layout = nil
        self.settingsView = nil
        self.kludge = nil
        self.forwardingView = nil
        self.parentVC?.canLoadInlineKeyboard = true
        
        NotificationCenter.default.removeObserver(self)
        }
        
    }
    
    func defaultsChanged(_ notification: Notification) {
        //let defaults = notification.object as? NSUserDefaults
        self.updateKeyCaps(self.shiftState.uppercase())
    }
    
    // without this here kludge, the height constraint for the keyboard does not work for some reason
    var kludge: UIView?
    func setupKludge() {
        if self.kludge == nil {
            let kludge = UIView()
            self.view.addSubview(kludge)
            kludge.translatesAutoresizingMaskIntoConstraints = false
            kludge.isHidden = true
            
            let a = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.left, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let b = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.right, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.left, multiplier: 1, constant: 0)
            let c = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            let d = NSLayoutConstraint(item: kludge, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1, constant: 0)
            self.view.addConstraints([a, b, c, d])
            
            self.kludge = kludge
        }
    }
    
    /*
     BUG NOTE
     
     For some strange reason, a layout pass of the entire keyboard is triggered
     whenever a popup shows up, if one of the following is done:
     
     a) The forwarding view uses an autoresizing mask.
     b) The forwarding view has constraints set anywhere other than init.
     
     On the other hand, setting (non-autoresizing) constraints or just setting the
     frame in layoutSubviews works perfectly fine.
     
     I don't really know what to make of this. Am I doing Autolayout wrong, is it
     a bug, or is it expected behavior? Perhaps this has to do with the fact that
     the view's frame is only ever explicitly modified when set directly in layoutSubviews,
     and not implicitly modified by various Autolayout constraints
     (even though it should really not be changing).
     */
    
    var constraintsAdded: Bool = false
    func setupLayout() {
        if !constraintsAdded {
            self.layout = type(of: self).layoutClass.init(model: self.keyboard, superview: self.forwardingView, layoutConstants: type(of: self).layoutConstants, globalColors: type(of: self).globalColors, darkMode: self.darkMode(), solidColorMode: self.solidColorMode())
            self.layout?.initialize()
            self.setMode(0)
            self.setupKludge()
            self.updateKeyCaps(self.shiftState.uppercase())
            //var capsWasSet = self.setCapsIfNeeded()
            self.updateAppearances(self.darkMode())
            self.constraintsAdded = true
        }
    }
    
    // only available after frame becomes non-zero
    func darkMode() -> Bool {
        let darkMode = { () -> Bool in
            let proxy = self.parentVC?.textDocumentProxy
            return proxy?.keyboardAppearance == UIKeyboardAppearance.dark
        }()
        
        return darkMode
    }
    
    func solidColorMode() -> Bool {
        return UIAccessibilityIsReduceTransparencyEnabled()
    }
    
    var lastLayoutBounds: CGRect?
    override open func viewDidLayoutSubviews() {
        if view.bounds == CGRect.zero {
            return
        }
        
        self.setupLayout()
        self.view.backgroundColor = GlobalColors.backgroundColor
        let orientationSavvyBounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.heightForOrientation(self.currentInterfaceOrientation, withTopBanner: false))
        
        if (lastLayoutBounds != nil && lastLayoutBounds == orientationSavvyBounds) {
            // do nothing
        }
        else {
            let uppercase = self.shiftState.uppercase()
            let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
            
            self.forwardingView.frame = orientationSavvyBounds
            self.layout?.layoutKeys(pageNum: self.currentMode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
            self.lastLayoutBounds = orientationSavvyBounds
            self.setupKeys()
        }
        
        // self.bannerView?.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: metric("topBanner"))
        
        let newOrigin = CGPoint(x: 0, y: self.view.bounds.height - self.forwardingView.bounds.height)
        self.forwardingView.frame.origin = newOrigin
        print("app mode is ", appMode)
    }
    
    open override func loadView() {
        super.loadView()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        self.keyboard = defaultKeyboard(self.appMode)
        //self.bannerView?.isHidden = false
        // self.keyboardHeight = self.heightForOrientation(self.currentInterfaceOrientation, withTopBanner: false)
    }
    
    open override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        // optimization: ensures smooth animation
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = true
            }
        }
        
        //  self.keyboardHeight = self.heightForOrientation(toInterfaceOrientation, withTopBanner: false)
        self.view.frame.size.width = self.view.superview!.frame.width
        
    }
    
    open override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        // optimization: ensures quick mode and shift transitions
        if let keyPool = self.layout?.keyPool {
            for view in keyPool {
                view.shouldRasterize = false
            }
        }
    }
    
    func heightForOrientation(_ orientation: UIInterfaceOrientation, withTopBanner: Bool) -> CGFloat {
        let isPad = UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad
        
        //TODO: hardcoded stuff
        let actualScreenWidth = (UIScreen.main.nativeBounds.size.width / UIScreen.main.nativeScale)
        let canonicalPortraitHeight = (isPad ? CGFloat(264) : CGFloat(orientation.isPortrait && actualScreenWidth >= 400 ? 226 : 216))
        let canonicalLandscapeHeight = (isPad ? CGFloat(352) : CGFloat(162))
        let topBannerHeight: CGFloat = 0.0
        
        return CGFloat(orientation.isPortrait ? canonicalPortraitHeight + topBannerHeight : canonicalLandscapeHeight + topBannerHeight)
    }
    
    /*
     BUG NOTE
     
     None of the UIContentContainer methods are called for this controller.
     */
    
    //override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
    //    super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    //}
    
    func setupKeys() {
        if self.layout == nil {
            return
        }
        
        for page in keyboard.pages {
            for (_, rowKeys) in page.rows.enumerated() { // TODO: quick hack
                for key in rowKeys {
                    if let keyView = self.layout?.viewForKey(model: key) {
                        keyView.removeTarget(nil, action: nil, for: UIControlEvents.allEvents)
                        
                        switch key.type {
                        case Key.KeyType.keyboardChange:
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.advanceTapped(_:)), for: .touchUpInside)
                        case Key.KeyType.backspace:
                            let cancelEvents: UIControlEvents = [UIControlEvents.touchUpInside, UIControlEvents.touchUpInside, UIControlEvents.touchDragExit, UIControlEvents.touchUpOutside, UIControlEvents.touchCancel, UIControlEvents.touchDragOutside]
                            
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.backspaceDown(_:)), for: .touchDown)
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.backspaceUp(_:)), for: cancelEvents)
                        case Key.KeyType.shift:
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.shiftDown(_:)), for: .touchDown)
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.shiftUp(_:)), for: .touchUpInside)
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.shiftDoubleTapped(_:)), for: .touchDownRepeat)
                        case Key.KeyType.modeChange:
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.modeChangeTapped(_:)), for: .touchDown)
                        case Key.KeyType.settings:
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.toggleSettings), for: .touchUpInside)
                        default:
                            break
                        }
                        
                        
                        
                        
                        if key.isCharacter {
                            
                            if UIDevice.current.userInterfaceIdiom != UIUserInterfaceIdiom.pad {
                                keyView.addTarget(self, action: #selector(InlineKeyboardViewController.showPopup(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
                                keyView.addTarget(keyView, action: #selector(KeyboardKey.hidePopup), for: [.touchDragExit, .touchCancel])
                                keyView.addTarget(self, action: #selector(InlineKeyboardViewController.hidePopupDelay(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside])
                            }
                        }
                        
                        if key.hasOutput {
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.keyPressedHelper(_:)), for: .touchUpInside)
                        }
                        
                        if key.type != Key.KeyType.shift && key.type != Key.KeyType.modeChange || key.type != Key.KeyType.empty {
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.highlightKey(_:)), for: [.touchDown, .touchDragInside, .touchDragEnter])
                            keyView.addTarget(self, action: #selector(InlineKeyboardViewController.unHighlightKey(_:)), for: [.touchUpInside, .touchUpOutside, .touchDragOutside, .touchDragExit, .touchCancel])
                        }
                        
                        keyView.addTarget(self, action: #selector(InlineKeyboardViewController.playKeySound), for: .touchDown)
                    }
                }
            }
        }
    }
    
    /////////////////
    // POPUP DELAY //
    /////////////////
    
    var keyWithDelayedPopup: KeyboardKey?
    var popupDelayTimer: Timer?
    
    func showPopup(_ sender: KeyboardKey) {
        if sender == self.keyWithDelayedPopup {
            self.popupDelayTimer?.invalidate()
        }
        sender.showPopup()
    }
    
    func hidePopupDelay(_ sender: KeyboardKey) {
        sender.hidePopup()
        return
        //        self.popupDelayTimer?.invalidate()
        //
        //        if sender != self.keyWithDelayedPopup {
        //            self.keyWithDelayedPopup?.hidePopup()
        //            self.keyWithDelayedPopup = sender
        //        }
        //
        //        if sender.popup != nil {
        //            self.popupDelayTimer = NSTimer.scheduledTimerWithTimeInterval(0.05, target: self, selector: #selector(InlineKeyboardViewController.hidePopupCallback), userInfo: nil, repeats: false)
        //        }
    }
    
    func hidePopupCallback() {
        self.keyWithDelayedPopup?.hidePopup()
        self.keyWithDelayedPopup = nil
        self.popupDelayTimer = nil
    }
    
    /////////////////////
    // POPUP DELAY END //
    /////////////////////
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated
    }
    
    // TODO: this is currently not working as intended; only called when selection changed -- iOS bug
    
    
    func contextChanged() {
        _ = self.setCapsIfNeeded()
        self.autoPeriodState = .noSpace
    }
    
    func setHeight(_ height: CGFloat) {
        if self.heightConstraint == nil {
            self.heightConstraint = NSLayoutConstraint(
                item:self.view,
                attribute:NSLayoutAttribute.height,
                relatedBy:NSLayoutRelation.equal,
                toItem:nil,
                attribute:NSLayoutAttribute.notAnAttribute,
                multiplier:0,
                constant:height)
            self.heightConstraint!.priority = 999
            self.view.addConstraint(self.heightConstraint!) // TODO: what if view already has constraint added?
        }
        else {
            self.heightConstraint?.constant = height
        }
    }
    
    func updateAppearances(_ appearanceIsDark: Bool) {
        //        self.layout?.solidColorMode = self.solidColorMode()
        //      self.layout?.darkMode = appearanceIsDark
        //        self.layout?.updateKeyAppearance()
        //
        //
        //        self.settingsView?.darkMode = appearanceIsDark
    }
    
    func highlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = true
    }
    
    func unHighlightKey(_ sender: KeyboardKey) {
        sender.isHighlighted = false
    }
    
    func keyPressedHelper(_ sender: KeyboardKey) {
        
        if let model = self.layout?.keyForView(key: sender) {
            self.keyPressed(model)
            
            // auto exit from special char subkeyboard
            if model.type == Key.KeyType.space || model.type == Key.KeyType.return {
                self.currentMode = 0
            }
                
            else if model.type == Key.KeyType.character {
                self.currentMode = 0
            }
            
            // auto period on double space
            // TODO: timeout
            
            self.handleAutoPeriod(model)
            // TODO: reset context
        }
        
        _ = self.setCapsIfNeeded()
    }
    
    func handleAutoPeriod(_ key: Key) {
        if !UserDefaults.standard.bool(forKey: kPeriodShortcut) {
            return
        }
        
        if self.autoPeriodState == .firstSpace {
            if key.type != Key.KeyType.space {
                self.autoPeriodState = .noSpace
                return
            }
            
            let charactersAreInCorrectState = { () -> Bool in
                let previousContext = self.parentVC?.textDocumentProxy.documentContextBeforeInput
                
                if previousContext == nil || (previousContext!).characters.count < 3 {
                    return false
                }
                
                var index = previousContext!.endIndex
                
//                index = <#T##Collection corresponding to `index`##Collection#>.index(before: index)
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
//                index = <#T##Collection corresponding to `index`##Collection#>.index(before: index)
                index = previousContext!.index(before: index)
                if previousContext![index] != " " {
                    return false
                }
                
//                index = <#T##Collection corresponding to `index`##Collection#>.index(before: index)
                index = previousContext!.index(before: index)
                let char = previousContext![index]
                if self.characterIsWhitespace(char) || self.characterIsPunctuation(char) || char == "," {
                    return false
                }
                
                return true
            }()
            
            if charactersAreInCorrectState {
                WKeyboard.utils.deleteBackwards()
                WKeyboard.utils.deleteBackwards()
                WKeyboard.utils.insertText(text: ".")
                WKeyboard.utils.insertText(text: " ")
                
                self.delegate?.didPressKey(".")
                self.delegate?.didPressKey(" ")
            }
            
            self.autoPeriodState = .noSpace
        }
        else {
            if key.type == Key.KeyType.space {
                self.autoPeriodState = .firstSpace
            }
        }
    }
    
    func cancelBackspaceTimers() {
        self.backspaceDelayTimer?.invalidate()
        self.backspaceRepeatTimer?.invalidate()
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = nil
    }
    
    func backspaceDown(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
        
        WKeyboard.utils.deleteBackwards()
        self.delegate?.didPressBackspace()
        _ = self.setCapsIfNeeded()
        
        // trigger for subsequent deletes
        self.backspaceDelayTimer = Timer.scheduledTimer(timeInterval: backspaceDelay - backspaceRepeat, target: self, selector: #selector(InlineKeyboardViewController.backspaceDelayCallback), userInfo: nil, repeats: false)
    }
    
    func backspaceUp(_ sender: KeyboardKey) {
        self.cancelBackspaceTimers()
    }
    
    func backspaceDelayCallback() {
        self.backspaceDelayTimer = nil
        self.backspaceRepeatTimer = Timer.scheduledTimer(timeInterval: backspaceRepeat, target: self, selector: #selector(InlineKeyboardViewController.backspaceRepeatCallback), userInfo: nil, repeats: true)
    }
    
    func backspaceRepeatCallback() {
        self.playKeySound()
        
        WKeyboard.utils.deleteBackwards()
        self.delegate?.didPressBackspace()
        _ = self.setCapsIfNeeded()
    }
    
    func shiftDown(_ sender: KeyboardKey) {
        self.shiftStartingState = self.shiftState
        
        if let shiftStartingState = self.shiftStartingState {
            if shiftStartingState.uppercase() {
                // handled by shiftUp
                return
            }
            else {
                switch self.shiftState {
                case .disabled:
                    self.shiftState = .enabled
                case .enabled:
                    self.shiftState = .disabled
                case .locked:
                    self.shiftState = .disabled
                }
                
                (sender.shape as? ShiftShape)?.withLock = false
            }
        }
    }
    
    func shiftUp(_ sender: KeyboardKey) {
        if self.shiftWasMultitapped {
            // do nothing
        }
        else {
            if let shiftStartingState = self.shiftStartingState {
                if !shiftStartingState.uppercase() {
                    // handled by shiftDown
                }
                else {
                    switch self.shiftState {
                    case .disabled:
                        self.shiftState = .enabled
                    case .enabled:
                        self.shiftState = .disabled
                    case .locked:
                        self.shiftState = .disabled
                    }
                    
                    (sender.shape as? ShiftShape)?.withLock = false
                }
            }
        }
        
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
    }
    
    func shiftDoubleTapped(_ sender: KeyboardKey) {
        self.shiftWasMultitapped = true
        
        switch self.shiftState {
        case .disabled:
            self.shiftState = .locked
        case .enabled:
            self.shiftState = .locked
        case .locked:
            self.shiftState = .disabled
        }
    }
    
    func updateKeyCaps(_ uppercase: Bool) {
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.updateKeyCaps(fullReset: false, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
    }
    
    func modeChangeTapped(_ sender: KeyboardKey) {
        if let toMode = self.layout?.viewToModel[sender]?.toMode {
            self.currentMode = toMode
        }
    }
    
    func setMode(_ mode: Int) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        let uppercase = self.shiftState.uppercase()
        let characterUppercase = (UserDefaults.standard.bool(forKey: kSmallLowercase) ? uppercase : true)
        self.layout?.layoutKeys(pageNum: mode, uppercase: uppercase, characterUppercase: characterUppercase, shiftState: self.shiftState)
        
        self.setupKeys()
    }
    
    func advanceTapped(_ sender: KeyboardKey) {
        self.forwardingView.resetTrackedViews()
        self.shiftStartingState = nil
        self.shiftWasMultitapped = false
        
        if appMode {
            delegate?.shouldDismissKeyboard()
            print("dimissing keyboard")
        } else {
            self.parentVC?.advanceToNextInputMode()
        }
    }
    
    @IBAction func toggleSettings() {
        // lazy load settings
        
        self.parentVC?.hideInlineKeyboard()
        
    }
    
    func setCapsIfNeeded() -> Bool {
        if self.shouldAutoCapitalize() {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .enabled
            case .enabled:
                self.shiftState = .enabled
            case .locked:
                self.shiftState = .locked
            }
            
            return true
        }
        else {
            switch self.shiftState {
            case .disabled:
                self.shiftState = .disabled
            case .enabled:
                self.shiftState = .disabled
            case .locked:
                self.shiftState = .locked
            }
            
            return false
        }
    }
    
    func characterIsPunctuation(_ character: Character) -> Bool {
        return (character == ".") || (character == "!") || (character == "?")
    }
    
    func characterIsNewline(_ character: Character) -> Bool {
        return (character == "\n") || (character == "\r")
    }
    
    func characterIsWhitespace(_ character: Character) -> Bool {
        // there are others, but who cares
        return (character == " ") || (character == "\n") || (character == "\r") || (character == "\t")
    }
    
    func stringIsWhitespace(_ string: String?) -> Bool {
        if string != nil {
            for char in (string!).characters {
                if !characterIsWhitespace(char) {
                    return false
                }
            }
        }
        return true
    }
    
    func shouldAutoCapitalize() -> Bool {
        if !UserDefaults.standard.bool(forKey: kAutoCapitalization) {
            return false
        }
        
        let traits = self.parentVC?.textDocumentProxy
        if let autocapitalization = traits?.autocapitalizationType {
            let documentProxy = self.parentVC?.textDocumentProxy
            //var beforeContext = documentProxy.documentContextBeforeInput
            
            switch autocapitalization {
            case .none:
                return false
            case .words:
                if let beforeContext = documentProxy?.documentContextBeforeInput {
                    let previousCharacter = beforeContext[beforeContext.characters.index(before: beforeContext.endIndex)]
                    return self.characterIsWhitespace(previousCharacter)
                }
                else {
                    return true
                }
                
            case .sentences:
                if let beforeContext = documentProxy?.documentContextBeforeInput {
                    guard !self.stringIsWhitespace(beforeContext) else {
                        return false
                    }
                    
                    let offset = min(3, beforeContext.characters.count)
                    var index = beforeContext.endIndex
                    
                    for i in 0...offset {
//                        index = <#T##Collection corresponding to `index`##Collection#>.index(before: index)
                        index = beforeContext.index(before: index)
                        let char = beforeContext[index]
                        
                        if characterIsPunctuation(char) {
                            if i == 0 {
                                return false //not enough spaces after punctuation
                            }
                            else {
                                return true //punctuation with at least one space after it
                            }
                        }
                        else {
                            if !characterIsWhitespace(char) {
                                return false //hit a foreign character before getting to 3 spaces
                            }
                            else if characterIsNewline(char) {
                                return true //hit start of line
                            }
                        }
                    }
                    
                    return true //either got 3 spaces or hit start of line
                }
                else {
                    return true
                }
            case .allCharacters:
                return true
            }
        }
        else {
            return false
        }
    }
    
    // this only works if full access is enabled
    func playKeySound() {
        if !UserDefaults.standard.bool(forKey: kKeyboardClicks) {
            return
        }
        
        DispatchQueue.global().async {
            AudioServicesPlaySystemSound(1104)
        }
    }
    
    //////////////////////////////////////
    // MOST COMMONLY EXTENDABLE METHODS //
    //////////////////////////////////////
    
    class var layoutClass: KeyboardLayout.Type { get { return KeyboardLayout.self }}
    class var layoutConstants: LayoutConstants.Type { get { return LayoutConstants.self }}
    class var globalColors: GlobalColors.Type { get { return GlobalColors.self }}
    
    func keyPressed(_ key: Key) {
        //self.parentVC.textDocumentProxy.insertText(key.outputForCase(self.shiftState.uppercase()))
        WKeyboard.utils.insertText(text: key.outputForCase(self.shiftState.uppercase()))
        
        switch key.type {
        case .backspace:
            self.delegate?.didPressBackspace()
        case .character, .specialCharacter, .space, .period:
            self.delegate?.didPressKey(key.outputForCase(self.shiftState.uppercase()))
        case .return:
            if appMode {
                self.delegate?.didPressShare()
            } else {
                self.delegate?.didPressKey(key.outputForCase(self.shiftState.uppercase()))
            }
        case .settings:
            WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "dismissinlinekeyboard")
            self.delegate?.shouldDismissKeyboard()
        default:
            return
        }
    }
    
    // a banner that sits in the empty space on top of the keyboard
    func createBanner() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        //return ExtraView(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        return nil
    }
    
    // a settings view that replaces the keyboard when the settings button is pressed
    func createSettings() -> ExtraView? {
        // note that dark mode is not yet valid here, so we just put false for clarity
        //        let settingsView = DefaultSettings(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode())
        //        settingsView.backButton?.addTarget(self, action: Selector("toggleSettings"), forControlEvents: UIControlEvents.TouchUpInside)
        return settingsView
    }
}

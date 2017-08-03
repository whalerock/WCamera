//
//  MainViewController.swift
//  Kimoji
//
//  Created by aramik on 3/3/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import UIKit
import WUtilities
import WNetwork
import WAssetManager
import WAnalytics
import ImageIO

open class MainViewController: UIInputViewController {
    
    let kKeyboardAspectRatio: CGFloat = 375.0/216.0
    var kKeywordHeight: CGFloat = 0.0

    var isInited = false
    
    // MARK: Interface Builder Outlets
    @IBOutlet weak open var headerContainerView: UIView!
    @IBOutlet weak open var accessoryContainerView: UIView!
    @IBOutlet weak open var contentStackView: UIStackView!
    @IBOutlet weak open var emojiContainerView: UIView!
    @IBOutlet weak open var toolbarContainerView: UIView!
    
    @IBOutlet weak open var contentStackViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak open var inlineKeyboardHeightConstraint: NSLayoutConstraint?
    fileprivate var inlineKeyboardHeight_portrait: CGFloat = 0.0
    fileprivate var inlineKeyboardHeight_landscape: CGFloat = 0.0
    fileprivate var inlineKeyboardTopConstraint: NSLayoutConstraint?
    fileprivate var mainViewHeightConstraint: NSLayoutConstraint?
    
    open var headerViewController: HeaderViewController?
    open var accessoryViewController: AccessoryViewController?
    open var emojiCollectionViewController: EmojiCollectionViewController?
    open var toolbarViewController: ToolBarViewController?
    
    //accessoryViewController children
    open var categoryCollectionViewController: CategoryCollectionViewController?
    open var keywordCollectionViewController: KeywordCollectionViewController?
    
    //instantiated when needed:
    fileprivate var mainContextViewController: UIViewController?
    //will be assigned to one of the following:
    fileprivate var connectionRequiredViewController: ConnectionRequiredViewController?
    fileprivate var downloadViewController: DownloadViewController?
    fileprivate var fullAccessRequiredViewController: FullAccessRequiredViewController?
    fileprivate weak var toneSelectorViewController: ToneSelectorViewController?
    fileprivate weak var inlineKeyboardViewController: InlineKeyboardViewController?
    
    
    // MARK: Public Initializers
    fileprivate var previousState: MainViewState?
    open fileprivate(set) var state: MainViewState = .preload {
        willSet {
            if self.previousState != self.state {
                self.previousState = self.state
            }
        }
    }
    //open fileprivate(set) var layoutContext: MainViewLayoutContext!
    open var isTransitionInlineKeyboard: Bool = false
    open var canLoadInlineKeyboard: Bool = true
    open var slowConnection: Bool = false
    open var downloader: WNDownloader?
    open var isParsing: Bool = false
    open var onFinishFetching: (() -> ())?
    
    // MARK: Private Initializers
    fileprivate var loggingEnabled: Bool = true
    fileprivate let notificationCenter = NotificationCenter.default
    fileprivate var hostApp: String! {
        get {
            return (self.inputViewController?.parent?.value(forKey: "_hostBundleID") as? String)?.lowercased() ?? "hostApplicationNA"
        }
    }
    fileprivate var favorites = Favorites()
    fileprivate var currentFavMenu: ALRadialMenu?
    fileprivate var isToneSelectorOpen = false
    
    // MARK: Override Lifecycle
    
    // TODO: why does the app crash if this isn't here?
    convenience init() {
        self.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    fileprivate func setupHeightConstraint() {
        inlineKeyboardHeight_portrait = (1/kKeyboardAspectRatio)*self.view.bounds.width
        if UIScreen.main.bounds.width < 375.0 {
            inlineKeyboardHeight_portrait += 30.0
        }
        inlineKeyboardHeight_landscape = 176.0
        mainViewHeightConstraint = NSLayoutConstraint(
            item:self.view,
            attribute:NSLayoutAttribute.height,
            relatedBy:NSLayoutRelation.equal,
            toItem:nil,
            attribute:NSLayoutAttribute.notAnAttribute,
            multiplier:1.0,
            constant:0)
        mainViewHeightConstraint!.priority = 999
        self.view.addConstraint(mainViewHeightConstraint!)
    }
    
    fileprivate func setHeight(_ height: CGFloat) {
        mainViewHeightConstraint!.constant = height //+ 100
    }
    
    fileprivate func configureHeight(for state: MainViewState) {
        guard headerContainerView != nil, accessoryContainerView != nil, contentStackView != nil, toolbarContainerView != nil else {
            return
        }
        
        /*switch state {
        case .downloadingContent:
            contentStackViewHeightConstraint?.constant = inlineKeyboardHeight - toolbarContainerView.bounds.height
            setHeight(inlineKeyboardHeight + headerContainerView.bounds.height)
        case .emoji:
            contentStackViewHeightConstraint?.constant = inlineKeyboardHeight - toolbarContainerView.bounds.height
            setHeight(inlineKeyboardHeight + headerContainerView.bounds.height)
        case .inlineKeyboard:
            contentStackViewHeightConstraint?.constant = inlineKeyboardHeight - toolbarContainerView.bounds.height
            setHeight(inlineKeyboardHeight + headerContainerView.bounds.height + kKeywordHeight)
        default:
            contentStackViewHeightConstraint?.constant = inlineKeyboardHeight - toolbarContainerView.bounds.height
            setHeight(inlineKeyboardHeight + headerContainerView.bounds.height)
        }*/
        
        if WKConfig.sharedInstance.showKeywordController {
            kKeywordHeight = 40.0
        }

        var inlineKeyboardHeight = inlineKeyboardHeight_portrait
        if !isPortrait {
            inlineKeyboardHeight = inlineKeyboardHeight_landscape
            if state == .inlineKeyboard {
                setHeight(inlineKeyboardHeight + headerContainerView.bounds.height + kKeywordHeight)
            } else {
                setHeight(toolbarContainerView.bounds.height + contentStackView.bounds.height + headerContainerView.bounds.height)
            }
        } else {
            if state == .inlineKeyboard {
                setHeight(inlineKeyboardHeight + headerContainerView.bounds.height + kKeywordHeight)
            } else {
                setHeight(toolbarContainerView.bounds.height + contentStackView.bounds.height + headerContainerView.bounds.height)
            }
        }
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        //WAnalytics.manager.autoConfigure()
        WKeyboard.utils.inputViewController = self
        WKManager.sharedInstance.delegate = self
        
        self.view.isOpaque = true
        self.view.backgroundColor = .white
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        self.initNotifications()
        self.setupHeightConstraint()
        self.headerViewController?.checkContainerAppButtonStatus()
        
    }
  
    func handleLongPress(_ gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state == .began {
            if emojiCollectionViewController?.type?.title?.lowercased() == "sticker" ||
                emojiCollectionViewController?.type?.title?.lowercased() == "stickers" {
                showMenu(sender: gestureReconizer, view: "sticker")
                return
            } else if emojiCollectionViewController?.type?.id?.lowercased() == "favorite" {
                showMenu(sender: gestureReconizer, view: "favorite")
                return

            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if WKeyboard.utils.hasOpenAccess {
            WNetwork.manager.startMonitoringConnection()
            self.setState(.loading, animated: false)
            load()
        } else {
            self.setState(.fullAccessRequired, animated: false)
        }
    }
    
    open func load() {
//        guard WNetwork.manager.hasConnection() == true else {
//            setState(.connectionRequired, animated: true)
//            return
//        }
        self.parseStoredConfig()
        WKeyboard.api.fetchPayload {
            self.parseStoredConfig()
            self.onFinishFetching?()
            self.headerViewController?.putMoreButtonTitle()
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.view.backgroundColor = GlobalColors.backgroundColor
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let pb = UIPasteboard.general
        pb.setValue("", forPasteboardType: UIPasteboardName.general.rawValue)

        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        self.notificationCenter.removeObserver(self)

        if self.downloader != nil {
            self.downloader?.queue?.cancelAllOperations()
            self.downloader = nil
        }
    }
    
    open override func didReceiveMemoryWarning() {
        self.log(.warning, message: "Received Memory Warning")
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        toolbarViewController?.willRotateDevice()
    }
    
    open func orientationDidChange(_ notification: Notification?) {
        
        var inlineKeyboardHeight = inlineKeyboardHeight_portrait
        if !isPortrait {
            inlineKeyboardHeight = inlineKeyboardHeight_landscape
        }
        
        if WKConfig.sharedInstance.showKeywordController {
            kKeywordHeight = 40.0
        }
        
        switch state {
        case .inlineKeyboard:
            setHeight(inlineKeyboardHeight + headerContainerView.bounds.height + kKeywordHeight)
        default:
            setHeight(toolbarContainerView.bounds.height + contentStackView.bounds.height + headerContainerView.bounds.height)
        }
        
        categoryCollectionViewController?.collectionView?.collectionViewLayout.invalidateLayout()
        keywordCollectionViewController?.collectionView?.collectionViewLayout.invalidateLayout()
        emojiCollectionViewController?.collectionView?.collectionViewLayout.invalidateLayout()
        
        inlineKeyboardHeightConstraint?.constant = inlineKeyboardHeight
        
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        
        toolbarViewController?.didRotateDevice()
        
        /*emojiCollectionViewController?.view.isHidden = true
        delay(0.2) {
            self.emojiCollectionViewController?.reload() {
                self.emojiCollectionViewController?.view.isHidden = false
            }
        }*/
        
    }
    
    deinit {
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
        self.notificationCenter.removeObserver(self)
        self.log(.log, message: "Deinitialized")
    }

    
    func showMenu(sender: UILongPressGestureRecognizer, view: String) {
        guard let emojiCollectionView = emojiCollectionViewController?.collectionView else {
            return
        }
        let pointInView = sender.location(in: emojiCollectionView)
        let indexPath = emojiCollectionView.indexPathForItem(at: pointInView)
        
        if let index = indexPath {
            if let cell = emojiCollectionView.cellForItem(at: index) as! EmojiCellView? {
                if let currentFavMenu = currentFavMenu {
                    currentFavMenu.dismiss()
                }
                currentFavMenu = ALRadialMenu()
                _ = currentFavMenu!.setStartAngle(270.0)
                    .setRadius(0.0)
                    .setCircumference(180.0)
                    .setButtons(generateButtons(sender: sender, view: view))
                    .setDelay(0.05)
                    .setAnimationOrigin(CGPoint(x: cell.center.x - emojiCollectionView.contentOffset.x, y: cell.center.y))
                    .presentInView(emojiCollectionView)
                
            }
        }
        
    }
    
    open func updateContainerAppButtonStatus () {
        self.headerViewController?.checkContainerAppButtonStatus()
    }
    
    func generateButtons(sender: UILongPressGestureRecognizer, view: String) -> [ALRadialMenuButton] {
        var buttons = [ALRadialMenuButton]()
        let pointInView = sender.location(in: emojiCollectionViewController!.view)
        
        let button = ALRadialMenuButton(frame: CGRect(x: 0, y: 0, width: 44, height: 44))
        if view == "sticker" {
            button.setImage(UIImage(named: "FavoriteIcon"), for: .normal)
        } else {
            button.setImage(UIImage(named: "UnfavoriteIcon"), for: .normal)
        }
        
        button.layer.cornerRadius = 22
        button.addTarget(self, action: #selector(MainViewController.handleFavoriteButtonPress(_:)), for: .touchUpInside)
        button.pointInView = pointInView
        buttons.append(button)
        
        return buttons
    }
    
    func handleFavoriteButtonPress(_ sender: ALRadialMenuButton!) {
        if let index = emojiCollectionViewController?.collectionView?.indexPathForItem(at: sender.pointInView!) {
            if let cell = emojiCollectionViewController?.collectionView?.cellForItem(at: index) as! EmojiCellView? {
                // save asset to favorite
                if emojiCollectionViewController?.type?.id == "favorite" {
                    
                    //removing favorite NOT Tracked for now
                    //WGA.manager.trackEvent("favorite", action: "remove", label: cell.asset.url, contentID: "\(cell.asset.id)")
                    
                    var favoritesCount = 0
                    
                    if let selectedType = categoryCollectionViewController?.type {
                        favorites.remove(asset: cell.asset)
                        selectedType.assets?.removeAll()
                        if let categories = selectedType.categories {
                            selectedType.categories?.removeAll()
                            categories.forEach { category in
                                if let assets = favorites.getAll(type: WKManager.sharedInstance.selectedType?.id ?? "none", category: category.id) {
                                    var tmpAssets = [WKAsset]()
                                    for asset in assets {
                                        tmpAssets.append(asset)
                                    }
                                    if tmpAssets.count > 0 {
                                        selectedType.categories?.append(category)
                                        selectedType.assets?.append(tmpAssets)
                                    }
                                    favoritesCount += assets.count
                                }
                            }
                        }
                        categoryCollectionViewController?.type = selectedType
                        emojiCollectionViewController?.collectionView?.reloadData()
                        
                        if favoritesCount == 0 {
                            self.setState(.favoriteDefault, animated: true)
                        }
                    }
    
                } else {
                    //adding favorite
                    WAnalytics.manager.sendEvent(.keyboard, action: .addfavorite, label: cell.asset.assetUrl, contentId:  "\(cell.asset.id)", contentCategory: nil, contentType: nil, contentName: nil)
                    _ = favorites.add(asset: cell.asset)
                }
            }
        } else {
            print("Could not find index path")
        }
    }
  
    fileprivate func parseStoredConfig() {
        guard self.isParsing == false else { return }
        
        if Thread.isMainThread {
            print("parseStoredConfig main")
        }
        
        WKeyboard.parser.parse { types, packs, categories, assets in

            guard types != nil, packs != nil, categories != nil, assets != nil else {
                self.isParsing = false
                return
            }
            
            guard self.downloader == nil else {
                self.setState(.downloadingContent, animated: true)
                return
            }
            
            self.isParsing = true

            if let firstCategory = categories?.first {
                if let categoryColor = firstCategory.color {
                    self.emojiCollectionViewController?.collectionView?.backgroundColor = UIColor(hex: categoryColor)
                }
            }

            self.downloadAssets(types!, packs!, categories!, assets!)
            
        }
    }
    
    func downloadAssets(_ types: [WKType], _ packs: [WKPack], _ categories: [WKCategory], _ assets: [String]) {
        if assets.count > 0 {
            
            if !WNetwork.manager.hasConnection() {
                self.setState(.connectionRequired, animated: false)
                return
            }
            self.setState(.downloadingContent, animated: true)
            
            self.downloader = WNDownloader(maxConncurrent: 5000)
            self.downloader?.download(assets, progressHandler: { savedAssetPath, progress in
                if let assetPath = savedAssetPath {
                    if let localAssetPath = WAssetManager.sharedInstance.localPathForAsset(fromUrl: assetPath) {
                        print(progress, localAssetPath)
                        
                        if self.downloadViewController != nil {
                            if !localAssetPath.contains("gif") && !localAssetPath.contains("apng") {
                                if let imgData = try? Data(contentsOf: URL(fileURLWithPath: localAssetPath)) {
                                    if let img = UIImage(data: imgData) {
                                        //let img = self.resizeImage(atPath: localAssetPath)
                                        DispatchQueue.main.async {
                                            self.downloadViewController?.slowConnectionTimer?.invalidate()
                                            self.downloadViewController?.statusLabel?.text = ""
                                            self.downloadViewController?.assetPreview?.image = nil
                                            self.downloadViewController?.assetPreview?.image = img
                                            self.downloadViewController?.progressView?.progress = Float(progress)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }, completionHandler: {
                
                print("downloaded completion handler")
                self.toolbarViewController?.types = types
                
                if self.state != .inlineKeyboard {
                    self.setState(MainViewState.emoji, animated: true)
                    delay (0.4) {
                        self.toolbarViewController?.setSelectedIndex(0)
                        self.isParsing = false
                    }
                }
                /*else {
                 self.previousState = .emoji
                 }*/
            })

            
        } else {
            
            self.toolbarViewController?.types = types
            
            if self.state != .inlineKeyboard {
                self.setState(MainViewState.emoji, animated: true)
                delay (0.4) {
                    self.toolbarViewController?.setSelectedIndex(0)
                    self.isParsing = false
                }
            }
            /*else {
             self.previousState = .emoji
             }*/
        }
    }
    
    func resizeImage(atPath: String) -> UIImage {
        // Create the image source
        let url = URL(fileURLWithPath: atPath)
        let src = CGImageSourceCreateWithURL(url as CFURL, nil)
        // Create thumbnail options
        let options = [
            kCGImageSourceCreateThumbnailWithTransform as String: true,
            kCGImageSourceCreateThumbnailFromImageAlways as String: true,
            kCGImageSourceThumbnailMaxPixelSize as String: 64
        ] as [String : Any]
        // Generate the thumbnail
        let thumbnail = CGImageSourceCreateThumbnailAtIndex(src!, 0, options as CFDictionary?)
        return UIImage(cgImage: thumbnail!)
    }

    open override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    
        if let vc = segue.destination as? HeaderViewController {
            vc.delegate = self
            headerViewController = vc
        }
        
        if let vc = segue.destination as? AccessoryViewController {
            accessoryViewController = vc
        }
        
        if let vc = segue.destination as? EmojiCollectionViewController {
            vc.delegate = self
            emojiCollectionViewController = vc
            if WKConfig.sharedInstance.wantsFavoritesEnabled {
                let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(MainViewController.handleLongPress(_:)))
                lpgr.delaysTouchesBegan = true
                lpgr.delegate = self
                emojiCollectionViewController!.view.addGestureRecognizer(lpgr)
            }
        }
        
        if let vc = segue.destination as? ToolBarViewController {
            vc.delegate = self
            toolbarViewController = vc
        }
        
    }
    
    // MARK: Lifecycle
    
    // MARK: Layout
    
    fileprivate func setState(_ newState: MainViewState?, animated:Bool) {
        guard newState != nil else {
            log(.log, message: "requesting previous (nil) state.")
            return
        }
        guard state != newState else {
            log(.log, message: "Blocked switching states; Already in desired state. \(state)")
            return
        }
        
        print("requesting: \(newState!)")
        configureHeight(for: newState!)
        
        if !Thread.isMainThread {
            fatalError()
        }
        
        switch newState! {
            case .preload:
                print("preloading.")
            case .loading:
                showContentView(for: .loading)
            case .emoji:
                showEmojiViewController()
                self.hideMainContextView()
            case .connectionRequired:
                showContentView(for: .connectionRequired)
            case .fullAccessRequired:
                showContentView(for: .fullAccessRequired)
            case .downloadingContent:
                showContentView(for: .downloadingContent)
            case .inlineKeyboard:
                self.showInlineKeyboard()
            case .favorite:
                print("favorites not implemented.")
                break
            case .favoriteDefault:
                showContentView(for: .defaultFavorites)
            default:
                return
        }
        
        //previousState = self.state //set in willSet
        state = newState!
        self.log(.log, message: "State changed to \(newState)")
    }
    
    fileprivate func showContentView(for context: MainViewContext, animated: Bool = false) {
        
        hideMainContextView()
        print("instantiating contentView for context: \(context)")
        
        switch context {
        case .loading:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_DownloadViewController") as? DownloadViewController {
                downloadViewController = vc
                mainContextViewController = vc
            }
        case .downloadingContent:
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_DownloadViewController") as? DownloadViewController {
                downloadViewController = vc
                mainContextViewController = vc
            }
        case .connectionRequired:
            toolbarViewController?.setState(ToolBarState.fullAccessRequired)
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_ConnectionRequiredViewController") as? ConnectionRequiredViewController {
                connectionRequiredViewController = vc
                mainContextViewController = vc
            }
        case .fullAccessRequired:
            self.toolbarViewController?.setState(ToolBarState.fullAccessRequired)
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_FullAccessRequiredViewController") as? FullAccessRequiredViewController {
                vc.delegate = self
                fullAccessRequiredViewController = vc
                mainContextViewController = vc
            }
            break
        case .defaultFavorites:
            print("MainViewContext: \(context) not implemented.")
        }
        
        if mainContextViewController != nil {
            self.addChildViewController(mainContextViewController!)
            mainContextViewController!.view.frame = contentStackView.frame
            self.view.addSubview(mainContextViewController!.view)
            
            if mainContextViewController is DownloadViewController {
                if context == .loading {
                    (mainContextViewController as! DownloadViewController).statusLabel.text = "LOADING..."
                }
            }
            
            mainContextViewController!.view.translatesAutoresizingMaskIntoConstraints = false
            mainContextViewController!.view.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor).isActive = true
            mainContextViewController!.view.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
            mainContextViewController!.view.bottomAnchor.constraint(equalTo: toolbarContainerView.topAnchor).isActive = true
            mainContextViewController!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
            
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
        
        contentStackView.isHidden = true
        
    }
    
    fileprivate func hideMainContextView(_ animated:Bool = false) {
        if downloadViewController != nil {
            downloadViewController?.slowConnectionTimer?.invalidate()
            downloadViewController?.assetPreview.image = nil
            downloadViewController?.assetPreview.removeFromSuperview()
            downloadViewController?.assetPreview = nil
            downloadViewController?.view.removeFromSuperview()
            downloadViewController?.removeFromParentViewController()
            downloadViewController = nil
        }
        
        mainContextViewController?.view.removeFromSuperview()
        mainContextViewController?.removeFromParentViewController()
        mainContextViewController = nil
        
        connectionRequiredViewController = nil
        fullAccessRequiredViewController = nil
        downloadViewController = nil
        toneSelectorViewController = nil
        
        contentStackView.isHidden = false
    }
    
    fileprivate func showEmojiViewController() {
        if categoryCollectionViewController == nil {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_CategoryCollectionViewController") as? CategoryCollectionViewController {
                guard accessoryViewController != nil else {
                    return
                }
                accessoryViewController?.addChildViewController(vc)
                accessoryViewController?.view.addSubview(vc.view)
                vc.view.frame = accessoryViewController!.view.bounds
                vc.delegate = self
                categoryCollectionViewController = vc
            }
        }
    }
    
    // MARK: InlineKeyboard Setup/Breakdown functions
    
    fileprivate func showInlineKeyboard() {
        guard canLoadInlineKeyboard else {
            return
        }
        guard self.inlineKeyboardViewController == nil else {
            self.log(.log, message: "InlineKeyboardView already setup, exiting.")
            return
        }
        
        canLoadInlineKeyboard = false
        isTransitionInlineKeyboard = true
        
        if let _inlineKeyboard = mainStoryboard().instantiateViewController(withIdentifier: "sb_InlineKeyboardViewController") as? InlineKeyboardViewController {
            
            var inlineKeyboardHeight = inlineKeyboardHeight_portrait
            if !isPortrait {
                inlineKeyboardHeight = inlineKeyboardHeight_landscape
            }
           
            inlineKeyboardViewController = _inlineKeyboard
            self.addChildViewController(inlineKeyboardViewController!)
            inlineKeyboardViewController!.parentVC = self
            inlineKeyboardViewController!.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: UIScreen.main.bounds.width, height: inlineKeyboardHeight)
            //216
            self.view.addSubview(self.inlineKeyboardViewController!.view)
            
            inlineKeyboardViewController!.view.translatesAutoresizingMaskIntoConstraints = false
            
            inlineKeyboardViewController!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
            inlineKeyboardViewController!.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
            
            //inlineKeyboardHeight constraint
            inlineKeyboardHeightConstraint = NSLayoutConstraint(item: inlineKeyboardViewController!.view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: inlineKeyboardHeight)
            self.view.addConstraint(inlineKeyboardHeightConstraint!)
            
            inlineKeyboardTopConstraint = NSLayoutConstraint(item: inlineKeyboardViewController!.view, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: self.view.bounds.height)
            self.view.addConstraint(inlineKeyboardTopConstraint!)
            
            if WKConfig.sharedInstance.showKeywordController {
                self.setupKeywordCollectionViewController()
            }
                
            emojiCollectionViewController?.collectionView?.visibleCells.forEach { cell in
                if let gifCell = cell as? EmojiCellView {
                    if gifCell.gifImageView != nil {
                        gifCell.gifImageView.stopAnimating()
                        //gifCell.gifImageView.animatedImage = nil
                    }
                }
            }
            
            self.log(.log, message: "'inlineKeyboardViewController' created!")
            
            self.keywordCollectionViewController?.collectionView?.alpha = 0
            self.view.layoutIfNeeded()
            
            UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                
                self.contentStackView.alpha = 1
                self.keywordCollectionViewController?.collectionView?.alpha = 1
                self.setHeight(inlineKeyboardHeight + self.kKeywordHeight + self.headerContainerView.bounds.height)
                self.inlineKeyboardTopConstraint?.constant = self.headerContainerView.bounds.height + self.kKeywordHeight
                self.view.layoutIfNeeded()
                
            }, completion: { finished in
                
                self.isTransitionInlineKeyboard = false
                print(self.inlineKeyboardViewController!.view.frame)
                
            })
        }

    }
    
    open func hideInlineKeyboard() {
        print("hiding to previousState: \(self.previousState)")
        self.setState(self.previousState, animated: false)
        contentStackView.alpha = 1
        guard self.inlineKeyboardViewController != nil  else {
            return
        }
        
        if WKConfig.sharedInstance.showKeywordController {
            breakdownKeywordCollectionViewController()
        }
        
        //self.refreshView()
        //self.restoreContext()
        self.isTransitionInlineKeyboard = true
        self.headerViewController?.restoreTitle()
        self.emojiCollectionViewController?.collectionView?.collectionViewLayout.invalidateLayout()
        
        UIView.animate(withDuration: 0.4, animations: {
            self.inlineKeyboardTopConstraint?.constant = self.view.bounds.height
            //self.configureHeight(for: .emoji)
            self.view.layoutIfNeeded()
        }, completion: { finished in
            self.inlineKeyboardViewController!.view.removeFromSuperview()
            self.inlineKeyboardViewController!.removeFromParentViewController()
            self.inlineKeyboardViewController = nil
            self.inlineKeyboardTopConstraint = nil
            
            //self.setHeightForContext()
            self.isTransitionInlineKeyboard = false
            
            //self.emojiCollectionViewController?.collectionView?.reloadData()
            self.emojiCollectionViewController?.collectionView?.visibleCells.forEach { cell in
                if let gifCell = cell as? EmojiCellView {
                    if gifCell.gifImageView != nil {
                        gifCell.gifImageView.startAnimating()
                    }
                }
            }
        
            if let previousSelectedTag = self.toolbarViewController?.previousSelectedTypeTag {
                //hot fix for loading with inlineKeyboard in view
                print("selectedTypeTag: \(previousSelectedTag)")
                if previousSelectedTag < 0 && WKeyboard.utils.hasOpenAccess {
                    delay(0.3) {
                        self.toolbarViewController?.setSelectedIndex(0)
                    }
                }
                delay(0.3) {
                    self.toolbarViewController?.updateSelectorPosition()
                }
            } else {
                self.toolbarViewController?.updateSelectorPosition()
            }
        })
    }
    
    open func setupKeywordCollectionViewController() {
        
        guard keywordCollectionViewController == nil else {
            return
        }
        
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_KeywordCollectionViewController") as? KeywordCollectionViewController {
            
            //vc.delegate = self
            self.addChildViewController(vc)
            vc.view.frame = CGRect(x: 0, y: headerContainerView.bounds.height, width: self.view.bounds.width, height: kKeywordHeight)
            self.view.addSubview(vc.view)
            self.keywordCollectionViewController = vc
            
            keywordCollectionViewController!.view.translatesAutoresizingMaskIntoConstraints = false
            keywordCollectionViewController!.view.rightAnchor.constraint(equalTo: self.view.rightAnchor, constant: 0.0).isActive = true
            keywordCollectionViewController!.view.leftAnchor.constraint(equalTo: self.view.leftAnchor, constant: 0.0).isActive = true
            keywordCollectionViewController!.view.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: 0.0).isActive = true
            self.view.addConstraint(NSLayoutConstraint(item: keywordCollectionViewController!.view, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1.0, constant: kKeywordHeight))
            
            self.view.setNeedsLayout()
        }
    
    }
    
    open func breakdownKeywordCollectionViewController() {
        guard keywordCollectionViewController != nil else {
            return
        }

        //WKManager.sharedInstance.wordGuessAssets = nil
        self.keywordCollectionViewController!.view.removeFromSuperview()
        self.keywordCollectionViewController!.removeFromParentViewController()
        self.keywordCollectionViewController = nil
        
        self.view.setNeedsLayout()
    }
    
    // MARK: NotificationCenter
    
    fileprivate func initNotifications() {
        print(WNetwork.manager.connectionType)
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        notificationCenter.addObserver(self, selector: #selector(orientationDidChange(_:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarFrame, object: nil)
        
        //notificationCenter.addObserver(self, selector: #selector(connectionStatusChanged(_:)), name: NSNotification.Name(rawValue: "WRINetworkConnectionStatus"), object: nil)
        
        print(WNetwork.manager.reachability)
        notificationCenter.addObserver(self, selector: #selector(connectionStatusChanged(_:)), name: NSNotification.Name(rawValue: WNetworkNotification.ConnectionChanged), object: nil)
    }
    
    open func connectionStatusChanged(_ sender: Notification) {
        if let connectionType = sender.userInfo?["connectionType"] as? String {
            
            print(connectionType)
            
            /*case notConnected
            case wwan
            case cellular
            case wiFi
            case failed*/
            
            if state == .downloadingContent || isParsing {
                if connectionType == "failed" || connectionType == "notConnected" {
                    self.setState(MainViewState.connectionRequired, animated: false)
                } else if previousState != .loading && previousState != .preload {
                    self.setState(self.previousState, animated: false)
                }
            }
        }
    }
    
    open override func textDidChange(_ textInput: UITextInput?) {
        emojiCollectionViewController?.didTapTextInput(self.textDocumentProxy.documentContextBeforeInput, contentAfter: self.textDocumentProxy.documentContextAfterInput)
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
    
}

extension MainViewController: FullAccessRequiredViewControllerDelegate {
    
    func didPressHowToInstall(_ sender: AnyObject?) {
        WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "fullaccesstutorial")
        _ = openURL(URL(string: "\(WKConfig.sharedInstance.containerAppDomain)howto")!)
    }

}

extension MainViewController: HeaderViewDelegate {
    public func didTapMoreButton() {
        WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "opencontainerapp")
        delay(0.4) {
            _ = self.openURL(URL(string: "\(WKConfig.sharedInstance.containerAppDomain)")!)
        }
    }
}

extension MainViewController: EmojiCollectionViewControllerDelegate {
    
    public func categoryViewRef() -> CategoryCollectionViewController? {
        return categoryCollectionViewController
    }

    public func shouldShowCategoryCollectionView(ofType type: WKType, animated: Bool) {
        guard categoryCollectionViewController != nil else {
            return
        }
        guard let categoryCount = type.categories?.count, categoryCount > 0, let assetCount = type.assets?.count, assetCount > 0 else {
            shouldHideCategoryCollectionView(animated: false)
            return
        }
        accessoryContainerView.isHidden = false
        //self.view.bringSubview(toFront: accessoryContainerView)
        categoryCollectionViewController?.reload()
        self.view.layoutIfNeeded()
    }
    
    public func shouldHideCategoryCollectionView(animated: Bool) {
        guard categoryCollectionViewController != nil else {
            return
        }
        accessoryContainerView.isHidden = true
        self.view.layoutIfNeeded()
    }
    
    public func shouldHighlightCategory(at indexPath: IndexPath, withNotification: Bool) {
        categoryCollectionViewController?.highlightCategory(at: indexPath, withNotification: withNotification)
    }
    
    public func shouldOpenToneSelector(_ asset: WKAsset) {
        if toneSelectorViewController == nil {
            if let vc = self.storyboard?.instantiateViewController(withIdentifier: "sb_ToneSelectorViewController") as? ToneSelectorViewController {
                vc.delegate = self
                vc.asset = asset
                mainContextViewController = vc
                
                self.addChildViewController(vc)
                vc.view.frame = contentStackView.frame
                vc.view.alpha = 0
                self.view.addSubview(vc.view)
                
                UIView.animate(withDuration: 0.2, animations: {
                    vc.view.alpha = 0.9
                }, completion: { _ in
                    vc.showAllTones(true)
                    self.isToneSelectorOpen = true
                })
                toneSelectorViewController = vc
            }
        }
    }
    
    public func closeToneSelector(animated: Bool) {
        if toneSelectorViewController != nil {
            hideMainContextView()
        }
    }
    
    public func didSelectItem(at indexPath: IndexPath) {
        print("didSelectItem at \(indexPath)")
    }
}

extension MainViewController: ToneSelectorViewControllerDelegate {
    
    public func shouldCloseToneSelector(animated: Bool) {
        closeToneSelector(animated: animated)
    }
    
}

extension MainViewController: WKManagerDelegate {
    public func selectionUpdated(_ index: Int) {
        (GlobalMainQueue).async {
//            self.emojiCollectionViewController?.reload()
//            self.categoryCollectionViewController?.reload()
        }
    }
}

extension MainViewController: ToolbarViewControllerDelegate {
    
    public func toolBarDidChangeType(sender: UIButton) {
        
        if let selectedButton = sender as? ToolBarIconButton {
            
            switch selectedButton.tag {
            case 100:
                if WKeyboard.utils.hasOpenAccess {
                    WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "nextkeyboard")
                }
                self.advanceToNextInputMode()
                return
            case 101:
                print("inlinekeyboard")
                if WKeyboard.utils.hasOpenAccess {
                    WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "inlinekeyboard")
                }
                self.setState(.inlineKeyboard, animated: true)
                return
            case 102:
                WKeyboard.utils.deleteBackwards()
                emojiCollectionViewController?.didTapBackspace()
                if WKeyboard.utils.hasOpenAccess {
                    WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "backspace")
                }
                return
            case 103:
                print("favorites")
                let headerNotification = HeaderViewNotification(type: .Default, text: "FAVORITES", autoHide: true)
                NotificationCenter.default.post(name: Notification.Name(rawValue: WKNotifications.HeaderViewDisplayStatus), object: headerNotification.userInfo())
                if let oldBrandType = toolbarViewController?.findTypeByName(name: "sticker") {
                    let brandType = WKType()
                    brandType.title = "Favorites"
                    brandType.id = "favorite"
                    brandType.display = oldBrandType.display
                    brandType.categories = [WKCategory]()
                    brandType.assets = [[WKAsset]]()
                    
                    var foundFavorites = false
                    if let categories = oldBrandType.categories {
                        categories.forEach { category in
                            if let assets = favorites.getAll(type: oldBrandType.id!, category: category.id) {
                                print("FAVORITES: \(assets)")
                                var tmpAssets = [WKAsset]()
                                for asset in assets {
                                    tmpAssets.append(asset)
                                }
                                if tmpAssets.count > 0 {
                                    brandType.categories!.append(category)
                                    brandType.assets!.append(tmpAssets)
                                    foundFavorites = true
                                }
                            }
                        }
                        emojiCollectionViewController?.collectionView?.setContentOffset(CGPoint.zero, animated: false)
                    }
                    if foundFavorites == false {
                        setState(.favoriteDefault, animated: false)
                    }
                    WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "favorites")
                }
                return
                
            default:
                print("didChangeType:: custom item selected.")
            }
            
            //for selecting of "emoji" and "gif" types
            WKManager.sharedInstance.selectedIndex = selectedButton.tag
            let title = WKManager.sharedInstance.getTypeTitle(WKManager.sharedInstance.selectedType?.id)
            WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: "\(title) Tab")
    
            //reset the category and scroll offset state, for simplicity
            //prevent setting state to emoji when called on loading
            if state != .inlineKeyboard {
                self.setState(.emoji, animated: false)
            }
            emojiCollectionViewController?.type = WKManager.sharedInstance.selectedType
            categoryCollectionViewController?.type = WKManager.sharedInstance.selectedType
            emojiCollectionViewController?.collectionView?.setContentOffset(CGPoint.zero, animated: false)
            
            var notifyCategory = true
            if let typeTitle = WKManager.sharedInstance.selectedType?.title?.lowercased() {
                if typeTitle.contains("gif") || typeTitle.contains("apng") {
                    emojiCollectionViewController?.numberOfRows = 1
                    notifyCategory = false
                } else {
                    if typeTitle.contains("sticker") || typeTitle.contains("sticker") {
                        emojiCollectionViewController?.numberOfRows = 2
                    }
                    if typeTitle.contains("emoji") || typeTitle.contains("emoji") {
                        emojiCollectionViewController?.numberOfRows = 3
                    }
                }
            }
            
            delay(0.2) {
                self.categoryCollectionViewController?.highlightCategory(at: IndexPath(row: 0, section: 0), withNotification: notifyCategory)
                self.categoryCollectionViewController?.lastSelectedCategoryIndex = 0
                //self.setHeightForContext()
            }
            
        }
    }
    
}

extension MainViewController: CategoryViewControllerDelegate {
    
    public func shouldScrollToCategory(_ category: WKCategory, at indexPath: IndexPath) {
        emojiCollectionViewController?.collectionView?.selectItem(at: indexPath, animated: false, scrollPosition: .left)

        if let categoryColor = category.color {
            emojiCollectionViewController?.collectionView?.backgroundColor = UIColor(hex: categoryColor)
        }

        if let categoryTitle = category.title {
            WAnalytics.manager.sendEvent(.keyboard, action: .tap, label: categoryTitle)
        }
    }
    
}

extension MainViewController: UIGestureRecognizerDelegate {}

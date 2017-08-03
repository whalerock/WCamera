//
//  WNDownloader.swift
//  WNetworkFrameworkq
//
//  Created by aramik on 7/8/16.
//  Copyright © 2016 Whalerock Industries. All rights reserved.
//

import Foundation
import WAssetManager

public protocol WNDownloaderDelegate {
    func prepareForDownload()
    func downloadWithProgress(_ asset:String?, progress: Double)
    func finishedDownloading()

}

open class WNDownloader {

    // MARK: Public vars
    open var queue: OperationQueue?
    open var delegate: WNDownloaderDelegate?
    private var completedOperationCount: Int = 0
    
    /**
     Downloads assets with progress and completion handlers.

     - parameter maxConncurrent: number of async connections allowed
     - returns: Instance of WNDownloader
     */
    public init(maxConncurrent: Int = 50) {
        self.queue = OperationQueue()
        self.queue?.maxConcurrentOperationCount = maxConncurrent
    }

    /**
     Download multiple assets with progress and completion handlers.

     - parameter assetUrls:         An array of url strings
     - parameter progressHandler:   Called after downloading each file.
     - parameter completionHandler: Called when all downloads are complete
     */
    open func download(_ assetUrls:[String], progressHandler:@escaping (_ savedAssetUrl:String?, _ progressCompleted:Double)->(), completionHandler:@escaping ()->()) {

        guard WNetwork.manager.hasConnection() == true else {
            print("Connection required to download assets!")
            completionHandler()
            return
        }
      
        if assetUrls.count > 1 {
            self.delegate?.prepareForDownload()
        }
        
        DispatchQueue.global().async {
            
            let dispatchGroup = DispatchGroup()
            self.completedOperationCount = 0
            let assetCount = assetUrls.count
            
            for i in 0..<assetUrls.count {
                let assetUrl = assetUrls[i]
                if let url = URL(string: assetUrl) {
                    
                    dispatchGroup.enter()
                    
                    autoreleasepool {

                        let operation = DownloadOperation(session: URLSession.shared, URL: url)
                        if WAssetManager.sharedInstance.localPathForAsset(fromUrl: assetUrl) == nil {
                            operation.completionBlock = {
                                if self.queue != nil {
                                    self.completedOperationCount += 1
                                    let percentCompleted: Double = (Double(self.completedOperationCount) / Double(assetCount))
                                    DispatchQueue.main.async {
                                        self.delegate?.downloadWithProgress(assetUrl, progress: percentCompleted)
                                        progressHandler(assetUrl, percentCompleted)
                                        dispatchGroup.leave()
                                    }
                                }
                            }
                            self.queue?.addOperation(operation)
                        }  else {
                            self.completedOperationCount += 1

                            dispatchGroup.leave()

                            print("[WNetworkDownloader]: Asset already stored")
                        }
                        
                    }
                }
            }
            dispatchGroup.notify(queue: DispatchQueue.main, execute: { 
                self.delegate?.finishedDownloading()
                completionHandler()
            })
        }
    }
}

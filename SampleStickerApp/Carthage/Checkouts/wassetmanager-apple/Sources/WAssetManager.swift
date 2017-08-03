//
//  WAssetManager.swift
//  WAssetManagerFramework
//
//  Created by aramik on 7/10/16.
//
//

import Foundation

open class WAssetManager {

    // MARK: Variables
    open static let sharedInstance = WAssetManager()

    fileprivate var fileManager: FileManager!
    fileprivate var documentsDirectory: URL!


    // MARK: Lifecycle
    public init() {
        self.fileManager = FileManager()
        self.documentsDirectory =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }


    // MARK: Functions

    /**
     Check if an asset as already been downloaded and saved to documents directory

     - parameter url: Secure (https) URL of asset

     - returns: Local documents directory path for asset
     */
    open func localPathForAsset(fromUrl url:String) -> String? {
        guard let localFilePath = self.destinationUrl(url)?.path , fileManager.fileExists(atPath: localFilePath) == true else {
            return nil
        }
        return localFilePath
    }

    open func sizeOfLocalFile(_ localFilePath: String) -> Float? {
        if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: localFilePath) {
            if let fileSize = fileAttributes[FileAttributeKey.size]  {
                let size = (fileSize as! NSNumber).uint64Value
                let sizekB = Float(size) / Float(1000.0)
                return sizekB
            }
        }

        return nil
    }

    /**
     Deletes all files saved in documents directory.  Commonly used for development purposes; Shouldn't be used in production.
     */
    open func clearAllFilesInDocumentsDirectory() {
        let documentPath = self.documentsDirectory.path
        do {
            let directoryContents = try fileManager.contentsOfDirectory(atPath: documentPath)
            for path in directoryContents {

                let documentsUrl =  fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destinationUrl = documentsUrl.appendingPathComponent(path)

                if fileManager.fileExists(atPath: destinationUrl.path) {
                    try fileManager.removeItem(atPath: destinationUrl.path)
                }
            }
        } catch {
            print("[WAssetManager]: Coudn't delete content in Documents Directory")
        }
    }

    /**
     Using the asset name provided through the URL, this function creates an associated documents directory path.

     - parameter url: Secure (https) URL of asset

     - returns: Path that can be used to read/write asset.
     */
    fileprivate func destinationUrl(_ url: String) -> URL? {
        guard
            url != "", let assetURL = URL(string: url)
            else {
            return nil
        }

        return self.documentsDirectory.appendingPathComponent(assetURL.lastPathComponent)
    }

}

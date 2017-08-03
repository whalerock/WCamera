//
//  NetworkOperation.swift
//  Kimoji
//
//  Created by aramik on 4/24/16.
//  Copyright © 2016 Whalerock. All rights reserved.
//

import Foundation
import WAssetManager

/// Asynchronous NSOperation subclass for downloading

open class DownloadOperation : AsynchronousOperation {
    open var task: URLSessionTask!

    init(session: URLSession, URL: Foundation.URL) {
        super.init()

        task = session.downloadTask(with: URL) { temporaryURL, response, error in
            defer {
                self.completeOperation()
            }

            guard error == nil && temporaryURL != nil else {
                print(error ?? "no error")
                self.cancel()
                self.completeOperation()
                return
            }


            do {
                let manager = FileManager.default
                let documents = try manager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                let destinationURL = documents.appendingPathComponent(URL.lastPathComponent)
                if manager.fileExists(atPath: destinationURL.path) {
                    try manager.removeItem(at: destinationURL)
                }
                try manager.moveItem(at: temporaryURL!, to: destinationURL)
               
                
            } catch let moveError {
                print(moveError)
            }
        }
    }

    override open func cancel() {
        task.cancel()
        super.cancel()
    }

    override open func main() {
        task.resume()
    }

}


/// Asynchronous Operation base class
///
/// This class performs all of the necessary KVN of `isFinished` and
/// `isExecuting` for a concurrent `NSOperation` subclass. So, to developer
/// a concurrent NSOperation subclass, you instead subclass this class which:
///
/// - must override `main()` with the tasks that initiate the asynchronous task;
///
/// - must call `completeOperation()` function when the asynchronous task is done;
///
/// - optionally, periodically check `self.cancelled` status, performing any clean-up
///   necessary and then ensuring that `completeOperation()` is called; or
///   override `cancel` method, calling `super.cancel()` and then cleaning-up
///   and ensuring `completeOperation()` is called.

open class AsynchronousOperation : Operation {

    override open var isAsynchronous: Bool { return true }

    fileprivate var _executing: Bool = false
    override open var isExecuting: Bool {
        get {
            return _executing
        }
        set {
            if (_executing != newValue) {
                self.willChangeValue(forKey: "isExecuting")
                _executing = newValue
                self.didChangeValue(forKey: "isExecuting")
            }
        }
    }

    fileprivate var _finished: Bool = false
    override open var isFinished: Bool {
        get {
            return _finished
        }
        set {
            if (_finished != newValue) {
                self.willChangeValue(forKey: "isFinished")
                _finished = newValue
                self.didChangeValue(forKey: "isFinished")
            }
        }
    }

    /// Complete the operation
    ///
    /// This will result in the appropriate KVN of isFinished and isExecuting

    func completeOperation() {
        if isExecuting {
            isExecuting = false
            isFinished = true
        }
    }

    override open func start() {
        if (isCancelled) {
            isFinished = true
            return
        }
        
        isExecuting = true
        
        main()
    }
}

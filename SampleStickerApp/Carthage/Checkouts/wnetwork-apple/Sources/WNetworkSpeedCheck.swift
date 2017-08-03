//
//  SpeedTest.swift
//  WNetworkFramework
//
//  Created by aramik on 7/10/16.
//
//

import Foundation

/// Downloads a given url and returns the speed at which it was downloaded at in mbps.
open class WNetworkSpeedCheck: NSObject, URLSessionDelegate, URLSessionDataDelegate {
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    var speedTestCompletionHandler: ((_ megabytesPerSecond: Double?, _ error: NSError?) -> ())?


    public init(url:String, timeout: TimeInterval, completionHandler:((_ megabytesPerSecond: Double?, _ error: NSError?) -> ())?) {
        super.init()

        let url = URL(string: url)!
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0
        speedTestCompletionHandler = completionHandler

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
    }

    open func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }

    open func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let elapsed = stopTime - startTime
        guard elapsed != 0 && (error == nil || (error?._domain == NSURLErrorDomain && error?._code == NSURLErrorTimedOut)) else {
            speedTestCompletionHandler!(nil, error as NSError?)
            return
        }

        let speed = elapsed != 0 ? Double(bytesReceived) / elapsed / 1024.0 / 1024.0 : -1
        speedTestCompletionHandler!(speed, nil)
    }
    
}

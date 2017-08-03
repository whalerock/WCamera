//
//  WNetwork.swift
//  WNetworkFramework
//
//  Created by aramik on 7/10/16.
//
//

import Foundation
import SystemConfiguration


// Dependencies
import WAssetManager


open class WNetwork {
    open static let manager = WNetwork()

    open fileprivate(set) var connectionType: WNetworkConnectionType = .notConnected {
        didSet {
            NotificationCenter.default.post(name: Notification.Name(rawValue: WNetworkNotification.ConnectionChanged), object: nil, userInfo: ["connectionType": "\(self.connectionType)"])
        }
    }

    open var reachability: Reachability!

    fileprivate init() {
        print("[WNetwork]: running.")
        reachability = Reachability()
    }

    open func startMonitoringConnection() {
        
//        do {
//            reachability = try Reachability.reachabilityForInternetConnection()
        
        //reachability = Reachability(hostname: "http://google.com")
        
//        } catch {
//            print("[WRINetwork]: Failed to initialize!")
//            self.connectionType = .failed
//        }

        reachability.whenReachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                if reachability.isReachableViaWiFi {
                    self.connectionType = .wiFi
                } else {
                    self.connectionType = .cellular
                }
            }
        }
        reachability.whenUnreachable = { reachability in
            // this is called on a background thread, but UI updates must
            // be on the main thread, like this:
            DispatchQueue.main.async {
                self.connectionType = .notConnected
            }
        }

        do {
            try reachability.startNotifier()
        } catch {
            print("failed to setup notifications")
        }
    }

    
    open func hasConnection() -> Bool {
      //return connectionType != .failed && connectionType != .notConnected
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        //swift3
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        print("isReachable: \(isReachable)")
        print("needsConnection: \(needsConnection)")
        return (isReachable && !needsConnection)
    }




    /**
     Get JSON from api endpoint

     - parameter url:             endpoint url
     - parameter responseHandler: handler provides json or error
     */
    open static func request(_ url: String, responseHandler:@escaping (_ error: NSError?, _ json:NSDictionary?)->()) {
        // TODO: Integrate speed check with each progress update to return mbps
        if let apiUrl = URL(string: url) {
            let request = NSMutableURLRequest(url: apiUrl)
            request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
            
            let task = URLSession.shared.dataTask(with: request as URLRequest) { data, response, error in
                if error != nil {
                    responseHandler(error as NSError?, nil)
                }

                if data != nil {
                    do {

                        if let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {

                            responseHandler(nil, json as NSDictionary?)

                        }
                    } catch {
                        print("json exception: \(error)")
                        responseHandler((error as NSError), nil)
                    }
                }
            }
            task.resume()
        }
    }


}

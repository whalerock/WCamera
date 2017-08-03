//
//  Router.swift
//
//  Created by sam phomsopha on 6/25/16.
//  Modified by sam phomsopha
//  Copyright © 2016 sam phomsopha. All rights reserved.
//

import UIKit

public class WRouter {
    public static let sharedInstance = WRouter()
    private var defaultStoryBoardId: String?
    private var routes = [WRoute]()
    private var defaultRoute: WRoute?
    private var routeQueue = [WRoute]()
    
    private init() {
        self.defaultRoute = nil
        self.defaultStoryBoardId = nil
        
        if let path = Bundle.main.path(forResource: "routes", ofType: "json") {
            if let jsonData = NSData(contentsOfFile: path) {
                do {
                    if let jsonArr = try JSONSerialization.jsonObject(with: jsonData as Data, options: .allowFragments) as? [String: Any] {
                    
                        if let _defaultStoryBoard = jsonArr["storyboard"] as! String? {
                            self.defaultStoryBoardId = _defaultStoryBoard
                        } else {
                            self.defaultStoryBoardId = nil
                        }
                        
                        if let _defaultRouteArr = jsonArr["defaultRoute"] as? [String: Any] {
                            
                            let className = _defaultRouteArr["class"] as! String?
                            let ident = _defaultRouteArr["identifier"] as! String?
                            let handler = _defaultRouteArr["handler"] as! String?
                            let presentationStyle = _defaultRouteArr["presentationStyle"] as! String?
                            
                            self.defaultRoute = WRoute(storyBoard: defaultStoryBoardId, path: "", indentifier: ident, routeClass: className, handler: handler, presentationStyle: presentationStyle)
                            
                        } else {
                            self.defaultRoute = nil
                        }
                        if let _routes = jsonArr["routes"] {
                            for (key, item) in _routes as! [String:AnyObject] {
                                let _className = item["class"] as! String?
                                let _ident = item["identifier"] as! String?
                                var _storyBoardId = item["storyBoardId"] as! String?
                                if _storyBoardId == nil {
                                    _storyBoardId = defaultStoryBoardId
                                }
                                
                                let _handler = item["handler"] as! String?
                                let _presentationStyle = item["presentationStyle"] as! String?
                                
                                routes.append(WRoute(storyBoard: _storyBoardId, path: key, indentifier: _ident, routeClass: _className, handler: _handler, presentationStyle: _presentationStyle))
                            }
                        }
                    }
                } catch {
                    self.defaultStoryBoardId = nil
                    self.defaultRoute = nil
                    print("error serializing JSON: \(error)")
                }
            } else {
                self.defaultStoryBoardId = nil
                self.defaultRoute = nil
            }
        } else {
            self.defaultStoryBoardId = nil
            self.defaultRoute = nil
        }
        
    }
    
    public func prepareToHandleRequest(url: NSURL) {
        //where are we going if just scheme add default route to queue
        guard var path = url.host else {
            //do we have default route
            if let _defaultRoute = defaultRoute {
                routeQueue.append(_defaultRoute)
            }
            return
        }
        
        if let spath = url.path {
            path = path + spath
        }
        for testRoute in routes {
            if testRoute.path == path {
                var foundRoute = testRoute
                foundRoute.url = url as URL!
                routeQueue.append(foundRoute)
            }
        }
    }
    
    public func handleQueueRequest(window: UIWindow) {
        if let route = routeQueue.first {
            print(route)
            routeQueue.removeFirst()
            //get current active story
            if let storyBoardName = route.storyBoard {
                let storyboard = UIStoryboard(name: storyBoardName, bundle: nil)
                //have handler? if so notify
                if let handler = route.handler {
                    
                    var info = [String : Any]()
                    
                    if let _ = route.url {
                        info["url"] = route.url!
                    }
                    
                    if let _ = route.storyBoard {
                        info["storyboardId"] = route.storyBoard!
                    }
                    
                    if let _ = route.indentifier {
                        info["identifier"] = route.indentifier!
                    }
                    
                    if let _ = route.routeClass {
                        info["className"] = route.routeClass!
                    }
                    
                    if let _ = route.handler {
                        info["handler"] = route.handler!
                    }
                    
//                  NotificationCenter.default.post(name: NSNotification.Name(rawValue: handler), object: route)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: handler), object: nil, userInfo: info)
                    
                    return
                }
                //start with story board Id
                if let storyBoardIdentifer = route.indentifier {
                    let viewToShow = storyboard.instantiateViewController(withIdentifier: storyBoardIdentifer) as UIViewController
                    self.presentView(viewControllToShow: viewToShow, window: window, presentationStyle: route.presentationStyle)
                    return
                }
                //try class name
                if let _className = route.routeClass {
                    let vClass = NSClassFromString(_className) as! UIViewController.Type
                    let viewControll = vClass.init()
                    self.presentView(viewControllToShow: viewControll, window: window, presentationStyle: route.presentationStyle)
                    return
                }
            }
        }
        
    }
    
    public func presentView(viewControllToShow: UIViewController, window: UIWindow, presentationStyle: String? = "push") {
        //check to see if root is navigation controller
        if let rootVC = window.rootViewController as? UINavigationController {
            //is the rootVC the current active controller?
            dismissNonRootViewControllerIfPresent(rootViewController: rootVC)
            //does the VC exist in UINAV stack?
            for existingVC in rootVC.viewControllers {
                if existingVC.isKind(of: viewControllToShow.self.classForCoder) {
                    rootVC.popToViewController(existingVC, animated: true)
                    return
                }
            }
            if rootVC.viewControllers.contains(viewControllToShow) {
                rootVC.popToViewController(viewControllToShow, animated: true)
            } else {
                //doesn't
                if let _presentationStyle = presentationStyle {
                    if (_presentationStyle == "present") {
                        rootVC.present(viewControllToShow, animated: true, completion: nil)
                    } else {
                        rootVC.pushViewController(viewControllToShow, animated: true)
                    }
                } else {
                    rootVC.pushViewController(viewControllToShow, animated: true)
                }
            }
            return
        }
        //ok must be just UIViewController
        if let rootVC = window.rootViewController {
            dismissNonRootViewControllerIfPresent(rootViewController: rootVC)
            rootVC.present(viewControllToShow, animated: true, completion: nil)
        }
        else {
            //we can't find the rootVC, fuck I don't know what to do
            window.rootViewController = viewControllToShow
        }
        
    }
    
    public func dismissNonRootViewControllerIfPresent(rootViewController: UIViewController) {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {            
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            
            if topController !== rootViewController {
                topController.dismiss(animated: true, completion: nil)
            }
        }
        return
    }
}

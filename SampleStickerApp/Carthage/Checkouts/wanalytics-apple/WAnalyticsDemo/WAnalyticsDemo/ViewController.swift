//
//  ViewController.swift
//  WAnalyticsDemo
//
//  Created by Aramik on 7/20/16.
//  Copyright © 2016 Aramik. All rights reserved.
//

import UIKit
import WAnalytics

class ViewController: UIViewController {

    @IBOutlet weak var tabBar: UITabBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        let button = UIButton(type: .system)
        
        button.waID = "test4"
        button.waCategory = "mainView"
        button.frame = CGRect(x: 10, y: 10, width: 40, height: 30)
        button.setTitle("test", for: UIControlState())
  
        button.addTarget(self, action: #selector(testAction2(_:)), for: .touchUpInside)
        self.view.addSubview(button)
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("appeared ")
    }
     func testAction2(_ sender:UIButton) {
        print("test2")
        let testvc = UIViewController()
        
        testvc.view.frame = self.view.frame
        testvc.view.backgroundColor = UIColor.red
        present(testvc, animated: true, completion: nil);
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [String : Any]?, context: UnsafeMutableRawPointer?) {
        print("here here")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    @IBAction func testAction(_ sender:AnyObject) {
        print("pressed")
        
    }

}

extension ViewController: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        print("tabar")
    }
}


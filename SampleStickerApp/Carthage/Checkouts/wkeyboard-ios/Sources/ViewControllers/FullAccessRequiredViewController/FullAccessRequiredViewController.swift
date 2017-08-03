//
//  FullAccessRequiredViewController.swift
//  WKeyboard
//
//  Created by David Hoofnagle on 8/19/16.
//  Copyright © 2016 Whalerock Industries. All rights reserved.
//

import UIKit

protocol FullAccessRequiredViewControllerDelegate {
    func didPressHowToInstall(_ sender: AnyObject?)
}

open class FullAccessRequiredViewController: UIViewController {

    var delegate: FullAccessRequiredViewControllerDelegate?
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func howToInstallPressed (_ sender: AnyObject?) {
        print("should open exploji how to url")
        delegate?.didPressHowToInstall(sender)
        //openURL(NSURL(string: "emojiexploji://howto")!)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

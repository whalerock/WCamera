//
//  AssetInputViewController.swift
//  WCamera
//
//  Created by David Hoofnagle on 8/2/17.
//  Copyright © 2017 Whalerock. All rights reserved.
//

import UIKit

public protocol AssetInputViewControllerDelegate: class {
    func viewControllerForAssetInput(completion: @escaping ((UIViewController?)->Void))
    func didCancel()
}

public class AssetInputViewController: UIViewController {

    public weak var delegate: AssetInputViewControllerDelegate?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        delegate?.viewControllerForAssetInput(completion: { viewController in
            
            if let cvc = viewController as? UICollectionViewController {
                self.addChildViewController(cvc)
                self.view.insertSubview(cvc.view, at: 0)
                cvc.view.frame = self.view.bounds
                cvc.view.backgroundColor = .red
                cvc.collectionView?.reloadData()
            }
            
        })
        
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction public func cancelPressed(sender: Any?) {
        delegate?.didCancel()
    }

}

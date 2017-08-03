//
//  ImageEditorViewController.swift
//  WCamera
//
//  Created by David Hoofnagle on 8/2/17.
//  Copyright © 2017 Whalerock. All rights reserved.
//

import UIKit

public protocol ImageEditorViewControllerDelegate {
    func viewControllerForAssetInput(completion: @escaping ((UIViewController?)->Void))
    func didCancel()
}

public class ImageEditorViewController: UIViewController {

    public var delegate: ImageEditorViewControllerDelegate?
    @IBOutlet public weak var backgroundImageView: UIImageView!
    
    var assetInputViewController: AssetInputViewController?
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func stickersPressed(sender: UIButton) {
        presentStickerAssets()
    }
    
    @IBAction func textPressed(sender: UIButton) {
        presentKeyboard()
    }
    
    @IBAction func sharePressed(sender: UIButton) {
        
    }
    
    @IBAction func cancelPressed(sender: UIButton) {
        delegate?.didCancel()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func presentKeyboard() {
        
    }
    
    func presentStickerAssets() {
        guard assetInputViewController == nil else {
            return
        }
        
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: "AssetInputViewController") as? AssetInputViewController {
            assetInputViewController = vc
            assetInputViewController!.delegate = self
            self.addChildViewController(assetInputViewController!)
            self.view.addSubview(assetInputViewController!.view)
            assetInputViewController!.view.frame = CGRect(x: 0, y: self.view.bounds.height, width: self.view.bounds.width, height: self.view.bounds.height * 0.4)
            UIView.animate(withDuration: 0.5, animations: { 
                self.assetInputViewController!.view.frame.origin.y = self.view.bounds.height - self.assetInputViewController!.view.bounds.height
            }) { finished in
                
            }
        }
    }

}

extension ImageEditorViewController: AssetInputViewControllerDelegate {
    
    public func didCancel() {
        guard assetInputViewController != nil else {
            print("ImageEditorViewController.AssetInputViewControllerDelegate.didCancel:: assetInputViewController is nil")
            return
        }
        
        UIView.animate(withDuration: 0.5, animations: {
            self.assetInputViewController!.view.frame.origin.y = self.view.bounds.height
        }) { finished in
            self.assetInputViewController?.view.removeFromSuperview()
            self.assetInputViewController?.removeFromParentViewController()
            self.assetInputViewController = nil
        }
    }
    
    public func viewControllerForAssetInput(completion: @escaping ((UIViewController?)->Void)) {
        delegate?.viewControllerForAssetInput(completion: { viewController in
            completion(viewController)
        })
    }
    
}

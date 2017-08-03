//
//  ViewController.swift
//  ExampleApplication
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import UIKit
import AVFoundation
import WCamera

class ViewController: UIViewController {
    
//    weak var delegate: WCameraDelegate?
//
//    var captureSession: AVCaptureSession!
//    var isSessionRunning: Bool!
//    var currentSettings: WCameraSettings!
//    var videoDevice: AVCaptureDevice!
//    var videoDeviceInput: AVCaptureDeviceInput!
//    var audioDevice: AVCaptureDevice!
//    var audioDeviceInput: AVCaptureDeviceInput!
//    var photoOutput: AVCapturePhotoOutput!
//    
//    var previewView: UIView!
//    var previewLayer: AVCaptureVideoPreviewLayer!
//    
//    var captureVideoDataOutput: AVCaptureVideoDataOutput!
//    var movieOutput: AVCaptureMovieFileOutput!
//    
//    var cameraDirection: WCameraDirection!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WCamera.shared.delegate = self
        let cameraSettings = WCameraSettings.init(quality: AVCaptureSessionPresetHigh, type: WCameraCaptureType.video, direction: WCameraDirection.front)
       
        WCamera.shared.start(cameraUsing: cameraSettings)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func takePic(sender: UIButton) {
        WCamera.shared.capturePhoto()
    }
    
    @IBAction func swapCameraPosition(sender: UIButton) {
        WCamera.shared.switchCameraPosition()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            
            let orient = UIApplication.shared.statusBarOrientation
            WCamera.shared.fixRotation(forOrientation: orient)
            
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            print("rotation completed")
        })
        
        super.viewWillTransition(to: size, with: coordinator)
    }

}

extension ViewController: WCameraDelegate {
   
    func wCameraDidFinishInitializing() {
        WCamera.shared.previewLayer.frame = self.view.frame
        WCamera.shared.previewView.frame.size.height -= 80
        self.view.insertSubview(WCamera.shared.previewView, at: 0)
    }
    
    func didCapture(image: UIImage) {
        let t = image
    }
    
}


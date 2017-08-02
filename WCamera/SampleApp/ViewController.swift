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

class ViewController: UIViewController, WCamera {
    
    weak var delegate: WCameraDelegate?

    var previewView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
     var stillImageOutput: AVCapturePhotoOutput!
    var captureVideoDataOutput: AVCaptureVideoDataOutput!
    var movieOutput: AVCaptureMovieFileOutput!
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureDevice: AVCaptureDevice!
    var cameraDirection: WCameraDirection!
    
    var captureSession: AVCaptureSession!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate = self
        let cameraSettings = WCameraSettings.init(quality: AVCaptureSessionPresetHigh, type: WCameraCaptureType.video, direction: WCameraDirection.front)
       
        start(cameraUsing: cameraSettings)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    @IBAction func takePic(sender: UIButton) {
        capturePhoto()
    }


}

extension ViewController: WCameraDelegate {
   
    func wCameraDidFinishInitializing() {
        previewLayer.frame = self.view.frame
        previewView.frame.size.height -= 80
        self.view.insertSubview(previewView, at: 0)
    }
    
    func didCapture(image: UIImage) {
        let t = image
    }
    
}


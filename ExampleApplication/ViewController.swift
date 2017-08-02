//
//  ViewController.swift
//  ExampleApplication
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import UIKit
import AVFoundation
import AGCamera

class ViewController: UIViewController, AGCamera {
   
    


    weak var delegate: AGCameraDelegate?


    var previewView: UIView!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    var captureVideoDataOutput: AVCaptureVideoDataOutput!
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureDevice: AVCaptureDevice!
    var cameraDirection: AGCameraDirection!
    
    var  captureSession: AVCaptureSession! 
   

    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.delegate = self
        let cameraSettings = AGCameraSettings.init(quality: AVCaptureSessionPresetHigh, type: AGCameraCaptureType.video, direction: AGCameraDirection.rear)
       
        do {
            try start(cameraUsing: cameraSettings)

        } catch let err {
            print(err)
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
    @IBAction func takePic(sender: UIButton) {
        capturePhoto()
    }


}

extension ViewController: AGCameraDelegate {
    func agCameraDidFinishInitializing() {
        
        previewLayer.frame = self.view.frame
        previewView.frame.size.height -= 80
        self.view.insertSubview(previewView, at: 0)
    }
    
    
    func didCapture(image: UIImage) {
        let t = image
        
    }
}


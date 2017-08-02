//
//  WCamera.swift
//  WCamera
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import CoreImage

public protocol WCamera: class, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    weak var delegate: WCameraDelegate? { get set }
    
    var captureSession: AVCaptureSession! { get set }
    var cameraDirection: WCameraDirection! { get set }
    var captureDeviceInput: AVCaptureDeviceInput! { get set }
    
    var previewView: UIView! { get set }
    var previewLayer: AVCaptureVideoPreviewLayer! { get set }
    func start(cameraUsing settings: WCameraSettings) throws
    
    var stillImageOutput: AVCapturePhotoOutput! { get set }
    var captureVideoDataOutput: AVCaptureVideoDataOutput! { get set }
    var movieOutput: AVCaptureMovieFileOutput! { get set }
    var captureDevice: AVCaptureDevice! { get set }
}

extension WCamera {
    
    private func setupPreviewView() {
        guard previewView == nil else { return }
        previewView = UIView.init(frame: UIScreen.main.bounds)
    }
    
    private func setupPreviewLayer() {
        guard captureSession != nil else {
            print("No captureSession available.")
            return
        }
        
        guard previewLayer == nil else { return }
        previewLayer = AVCaptureVideoPreviewLayer.init(session: captureSession)
        previewLayer.bounds = previewView.frame
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspect
        previewView.layer.addSublayer(previewLayer)
    }
    
    private func getCameraDevice(direction: WCameraDirection) -> AVCaptureDevice?{
        let videoDevices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)
        
        for device in videoDevices! {
            let t = device as! AVCaptureDevice
            switch direction {
            case .rear:
                if t.position == AVCaptureDevicePosition.back {
                    self.cameraDirection = .rear
                    captureDevice = t
                    return t
                }
            case .front:
                if t.position == AVCaptureDevicePosition.front {
                    self.cameraDirection = .front
                    captureDevice = t
                    return t
                }
            }
            
        }
        return nil
    }

    public func start(cameraUsing settings: WCameraSettings)  {
       
        captureSession = AVCaptureSession.init()
        
        setupPreviewView()
        setupPreviewLayer()
        
        captureSession.sessionPreset = settings.quality
        
        captureDevice = getCameraDevice(direction: settings.direction)
        
        do {
            captureDeviceInput = try AVCaptureDeviceInput.init(device: captureDevice)
            
            captureSession.beginConfiguration()
            
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            } else {
                throw(NSError.init(domain: "Something is wrong, can't add device as input.", code: 3, userInfo: nil))
            }
            
            captureVideoDataOutput = AVCaptureVideoDataOutput()
            captureVideoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
            let queue = DispatchQueue(label: "com.whalerock.WCamera.captureQueue")
            captureVideoDataOutput.setSampleBufferDelegate(self, queue: queue)
            
            if captureVideoDataOutput != nil && captureSession.canAddOutput(captureVideoDataOutput) {
                captureSession.addOutput(captureVideoDataOutput)
            }
            
            if movieOutput != nil && captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
            if stillImageOutput != nil && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
            }
            
            captureSession.commitConfiguration()
            captureSession.startRunning()
            delegate?.wCameraDidFinishInitializing()
            
        } catch let error as NSError {
            print("error:", error)
        }
    }
    
    
    public func capturePhoto() {
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        self.stillImageOutput.capturePhoto(with: settings, delegate: self)
        
    }
    
    func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: NSError?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            if let image = UIImage.init(data: dataImage) {
                delegate?.didCapture?(image: image)
            }
        }
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
    }
 
}


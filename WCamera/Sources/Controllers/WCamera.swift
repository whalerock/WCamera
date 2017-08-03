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

//public protocol WCamera: class, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
//    weak var delegate: WCameraDelegate? { get set }
//    
//    var captureSession: AVCaptureSession! { get set }
//    var isSessionRunning: Bool! { get }
//    var videoDevice: AVCaptureDevice! { get set }
//    var videoDeviceInput: AVCaptureDeviceInput! { get set }
//    var audioDevice: AVCaptureDevice! { get set }
//    var audioDeviceInput: AVCaptureDeviceInput! { get set }
//    var photoOutput: AVCapturePhotoOutput! { get set }
//    
//    var cameraDirection: WCameraDirection! { get set }
//
//    var previewView: UIView! { get set }
//    var previewLayer: AVCaptureVideoPreviewLayer! { get set }
//    func start(cameraUsing settings: WCameraSettings) throws
//    
//    var captureVideoDataOutput: AVCaptureVideoDataOutput! { get set }
//    
//    var currentSettings: WCameraSettings! { get set }
//    
//}

public class WCamera: NSObject {
    
    public static let shared = WCamera()
    
    public weak var delegate: WCameraDelegate?
    
    var captureSession: AVCaptureSession!
    var isSessionRunning: Bool!
    var videoDevice: AVCaptureDevice!
    var videoDeviceInput: AVCaptureDeviceInput!
    var audioDevice: AVCaptureDevice!
    var audioDeviceInput: AVCaptureDeviceInput!
    var photoOutput: AVCapturePhotoOutput!

    var cameraDirection: WCameraDirection!

    public var previewView: UIView!
    public var previewLayer: AVCaptureVideoPreviewLayer!
    //func start(cameraUsing settings: WCameraSettings) throws

    var captureVideoDataOutput: AVCaptureVideoDataOutput!
    var currentSettings: WCameraSettings!
    
    private func setupPreviewView() {
        guard previewView == nil else { return }
        previewView = UIView(frame: UIScreen.main.bounds)
    }
    
    private func setupPreviewLayer() {
        guard captureSession != nil else {
            print("No captureSession available.")
            return
        }
        
        guard previewLayer == nil else { return }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
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
                    videoDevice = t
                    return t
                }
            case .front:
                if t.position == AVCaptureDevicePosition.front {
                    self.cameraDirection = .front
                    videoDevice = t
                    return t
                }
            }
            
        }
        return nil
    }

    public func start(cameraUsing settings: WCameraSettings)  {
       
        captureSession = AVCaptureSession()
        captureSession.beginConfiguration()
        
        setupPreviewView()
        setupPreviewLayer()
        
        captureSession.sessionPreset = settings.quality
        
        // Add video input.
        do {
            videoDevice = getCameraDevice(direction: settings.direction)
            
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            else {
                print("Could not add video device input to the session")
                captureSession.commitConfiguration()
                return
            }
        }
        catch {
            print("Could not create video device input: \(error)")
            captureSession.commitConfiguration()
            return
        }
        
        // Add audio input.
        do {
            audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if captureSession.canAddInput(audioDeviceInput) {
                captureSession.addInput(audioDeviceInput)
            }
            else {
                print("Could not add audio device input to the session")
            }
        }
        catch {
            print("Could not create audio device input: \(error)")
        }
        
        // Add video output
        captureVideoDataOutput = AVCaptureVideoDataOutput()
        let newSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA as UInt32)]
        captureVideoDataOutput.videoSettings = newSettings
        captureVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        let queue = DispatchQueue(label: "com.whalerock.WCamera.captureQueue")
        captureVideoDataOutput.setSampleBufferDelegate(self, queue: queue)
        if captureVideoDataOutput != nil && captureSession.canAddOutput(captureVideoDataOutput) {
            captureSession.addOutput(captureVideoDataOutput)
        }
        
        // Add photo output.
        photoOutput = AVCapturePhotoOutput()
        photoOutput.isHighResolutionCaptureEnabled = true
        photoOutput.isLivePhotoCaptureEnabled = photoOutput.isLivePhotoCaptureSupported
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        else {
            print("Could not add photo output to the session")
            captureSession.commitConfiguration()
            return
        }
        
        currentSettings = settings
        captureSession.commitConfiguration()
        
        captureSession.startRunning()
        delegate?.wCameraDidFinishInitializing()
        
    }
    
    public func pauseSession() {
        captureSession.stopRunning()
    }
    
    public func resumeSession() {
        captureSession.startRunning()
    }
    
    public func switchCameraPosition() {
        captureSession.beginConfiguration()
        
        captureSession.removeInput(videoDeviceInput)
        let newDirection = currentSettings.direction == WCameraDirection.front ? WCameraDirection.rear : WCameraDirection.front
        currentSettings.direction = newDirection
        videoDevice = getCameraDevice(direction: newDirection)
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
            }
            else {
                print("Could not add video device input to the session")
                captureSession.commitConfiguration()
                return
            }
        } catch {
            print("WCamera.switchCameraPosition:: exception: Couldn't switch camera position")
            captureSession.commitConfiguration()
            return
        }
    
        captureSession.commitConfiguration()
    }
    
    public func capturePhoto() {
        
        let settings = AVCapturePhotoSettings()
        let previewPixelType = settings.availablePreviewPhotoPixelFormatTypes.first!
        let previewFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPixelType,
                             kCVPixelBufferWidthKey as String: 160,
                             kCVPixelBufferHeightKey as String: 160]
        settings.previewPhotoFormat = previewFormat
        self.photoOutput.capturePhoto(with: settings, delegate: self)
        
    }
    
    public func fixRotation(forOrientation orientation: UIInterfaceOrientation) {
        
        if (previewLayer.connection.isVideoOrientationSupported) {
            switch (orientation) {
                case .portrait:
                    previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                case .portraitUpsideDown:
                    previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
                case .landscapeLeft:
                    previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                case .landscapeRight:
                    previewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                default:
                    print("unknown UIInterfaceOrientation")
                    break
            }
        }
        
    }
    
}

extension WCamera: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
    
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
    }
    
}

extension WCamera: AVCapturePhotoCaptureDelegate {
    
    public func capture(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhotoSampleBuffer photoSampleBuffer: CMSampleBuffer?, previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
            if let image = UIImage(data: dataImage),
                let fixedImage = fixOrientation(image: image),
                let finalImage = fixMirror(image: fixedImage) {
                
                delegate?.didCapture?(image: finalImage)
            }
        }
    }
    
    func fixMirror(image: UIImage) -> UIImage? {
        if currentSettings.direction == .rear {
            return image
        }
        
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0);
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.translateBy(x: 0.0, y: size.height)
        ctx.scaleBy(x: 1.0, y: -1.0)
        ctx.translateBy(x: size.width, y: 0.0)
        ctx.scaleBy(x: -1.0, y: 1.0)
        ctx.draw(image.cgImage!, in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let mirrorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return mirrorImage
    }
    
    func fixOrientation(image: UIImage) -> UIImage? {
        if image.imageOrientation == .up {
            return image
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform = CGAffineTransform.identity
        
        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: image.size.height)
            transform = transform.rotated(by: CGFloat(Double.pi))
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.rotated(by:  CGFloat(Double.pi / 2))
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: image.size.height)
            transform = transform.rotated(by:  -CGFloat(Double.pi / 2))
        default:
            break
        }
        
        switch image.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: image.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: image.size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        guard let context = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: image.cgImage!.bitsPerComponent, bytesPerRow: 0, space: image.cgImage!.colorSpace!, bitmapInfo: image.cgImage!.bitmapInfo.rawValue) else {
            return nil
        }
        
        context.concatenate(transform)
        
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
        default:
            context.draw(image.cgImage!, in: CGRect(origin: .zero, size: image.size))
        }
        
        // And now we just create a new UIImage from the drawing context
        guard let CGImage = context.makeImage() else {
            return nil
        }
        
        return UIImage(cgImage: CGImage)
    }
    
}


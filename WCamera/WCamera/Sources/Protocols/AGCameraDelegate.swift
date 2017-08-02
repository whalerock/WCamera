//
//  WCameraDelegate.swift
//  WCamera
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import Foundation
import AVFoundation

@objc public protocol WCameraDelegate: class {
    @objc optional func wCameraCaptureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    @objc optional func wCameraCaptureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    @objc optional func wCameraCapture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!)
    @objc optional func wCamera(shouldPresentPreviewController withImage:UIImageView)
    func wCameraDidFinishInitializing()
    @objc optional func didCapture(image: UIImage)
}


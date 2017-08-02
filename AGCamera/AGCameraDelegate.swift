//
//  AGCameraDelegate.swift
//  AGCamera
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import Foundation
import AVFoundation

@objc public protocol AGCameraDelegate: class {
    @objc optional func agCameraCaptureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    @objc optional func agCameraCaptureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    @objc optional func agCameraCapture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!)
    @objc optional func agCamera(shouldPresentPreviewController withImage:UIImageView)
    func agCameraDidFinishInitializing()
    @objc optional func didCapture(image: UIImage)
}


//
//  WCameraSettings.swift
//  WCamera
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import Foundation

public class WCameraSettings {
    public var quality: String!
    public var type: WCameraCaptureType!
    public var direction: WCameraDirection!
    
    public init(quality: String, type: WCameraCaptureType, direction: WCameraDirection) {
        self.quality = quality
        self.type = type
        self.direction = direction
    }
}

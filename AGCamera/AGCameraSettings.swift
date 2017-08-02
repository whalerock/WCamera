//
//  AGCameraSettings.swift
//  AGCamera
//
//  Created by Aramik on 5/12/17.
//  Copyright © 2017 aramikg. All rights reserved.
//

import Foundation

public class AGCameraSettings {
    public var quality: String!
    public var type: AGCameraCaptureType!
    public var direction: AGCameraDirection!
    
    public init(quality: String, type: AGCameraCaptureType, direction: AGCameraDirection) {
        self.quality = quality
        self.type = type
        self.direction = direction
    }
}

//
//  DefaultConfig.swift
//  WCamera
//
//  Created by David Hoofnagle on 8/2/17.
//  Copyright © 2017 Whalerock. All rights reserved.
//

import Foundation
import WConfig

public struct DefaultConfig:DefaultConfigDataSource {
    public let configData: Dictionary<String, Any> = [
        "analytics": ["ga": ["accountId": "UA-54312694-29"]],
        "kochava": ["appId": "kokimoji56e0c2f7f3386"],
        "newrelic": ["appId": "AA04e8307dd65edd19cbab0daa34e8f2044846d8d1"],
        "sns": ["CognitoIdentityPoolId": "us-east-1:1cb064d9-6095-4138-8822-468572a29287",
                "PlatformApplicationArn": "arn:aws:sns:us-east-1:139903529341:app/APNS/production-kimoji-ios",
                "TopicArnProduction": "arn:aws:sns:us-east-1:139903529341:production-kimoji",
                "TopicArnProductionPush": "arn:aws:sns:us-east-1:139903529341:production-kimoji-iospush"
        ],
        "wri": [
            "endpoint": "https://d3q6cnmfgq77qf.cloudfront.net/keyboards/kimoji/testing/v2/main-manifest-ios.json",
        ]
    ]
}

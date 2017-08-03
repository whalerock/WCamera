### WConfig
WConfig is a configuration manager for iOS App written in Swift.

## Documentation
WConfig requires that you set at least the default datasource.  Setting the production datasource is optional.  WConfig is initialized for production evironment. Therefore you will only need to set the debug or develop environment only if it's applicable.

## Usage
Before you can use WConfig, you need to create a struct or class that conforms to DefaultConfigDataSource protocol. Optionally you can also create a struct that conforms to ProductionConfigDataSource to hold production specific values.

```swift
// DefaultConfig.swift
// Swift
import Foundation
import WConfig

struct DefaultConfig:DefaultConfigDataSource {
    let configData: Dictionary<String, AnyObject> = [
        "wri": [
            "main-manifest": "http://d3q6cnmfgq77qf.cloudfront.net/keyboards/blitzmoji/testing/main-manifest-ios.json"
        ]
    ]
}
```

```swift
// ProductionConfig.swift
// Swift
import Foundation
import WConfig

struct ProductionConfig: ProductionConfigDataSource {
    let configData: Dictionary<String, AnyObject> = [
        "wri": [
            "main-manifest": "http://d3q6cnmfgq77qf.cloudfront.net/keyboards/blitzmoji/main-manifest-ios.json"
        ]
    ]
}
```

In your app delegate, initialize WConfig and set the datasource.

```swift
// Swift

import WConfig

func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
  let wconfig = WConfig.sharedInstance
          if let environment = NSBundle.mainBundle().objectForInfoDictionaryKey("Configuration") {
               if environment as! String == "Debug" {
                    wconfig.setEnvironment(WEnvironment.dev)
               }
          }
          wconfig.defaultDataSource = DefaultConfig()
          wconfig.productionDataSource = ProductionConfig()
}
```

Now you can lookup any defined config values using WConfig.sharedInstance.

```swift

let wriEndPoint = WConfig.sharedInstance.get("wri.main-manifest") as! String!

```

# Swift Configuration Variable
To gain access to Swift configuration variable, add the following to your project's plist.

```
Configuration = ${CONFIGURATION}
```



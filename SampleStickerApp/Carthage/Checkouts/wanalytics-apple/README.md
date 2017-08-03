# WAnalytics
Automated tracking framework.

By extending certain classes from UIKit, WAnalytics is able to provided automated tracking for all buttons and views without any additional code.  WAnalytics also makes tracking varaibles available to storyboards via the Attributes Inspector as well.


##### Getting Started
1. Add WAnalytics to your Cartfile (Carthage)
2. Link the framework with your Application
3. In your `AppDelegate` `application:didFinishLaunchingWithOptions:`
    - call `WAnalytics.manager.setupGA("GA_ACCOUNT_ID")`
4. Enojy!


##### Integrated Services
- Google Analytics
- New Relic *(coming soon)*
- Kochava *(coming soon)*
- Facebook Insights *(coming soon)*

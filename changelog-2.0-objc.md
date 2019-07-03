
# iOS Mobile SDK Changelog v2.0

## Dependencies
* FirebaseDynamicLinks => 4.0.0
* FirebaseMessaging => 4.0.2

## Versioning
The below will allow any newer minor version of  `OptimoveSDK`  not to break the existing API (i.e 2._._) and will be auto-fetched during any  `pod update`.
OptimoveSDK uses __semantic versioning__. Therefore, in your  `Podfile`  set the pod version with the  `~>`  sign.

Example code snippet:
```ruby
platform :ios, '10.0'
# Update "target" accordingly to support silent minor upgrades:
target '<YOUR_TARGET_NAME>' do
    use_frameworks!
    pod 'OptimoveSDK', '~> 2.0'
end

target 'Notification Extension' do
    use_frameworks!
    pod 'OptimoveNotificationServiceExtension','~> 2.0'
end
```

## Features
### Screen Visit function
Aligned all Web & Mobile SDKs to use the same naming convention for this function.

- Change from 
```objc
[Optimove.sharedInstance reportScreenVisitWithViewControllersIdentifiers: @[@"Home", @"Store", @"Footware", @"Boots"] url: @"<OPTIONAL: YOUR_URL>" category: @"<OPTIONAL: YOUR_CATEGORY>"];
```

- To pass the path as a String literal:
```objc
[Optimove.shared setScreenVisitWithScreenPath: @"Home/Store/Footware/Boots" screenTitle: @"<YOUR_TITLE>" screenCategory: @"<OPTIONAL: YOUR_CATEGORY>"];
```
- Or an array of screen titles
Added a screen reporting function which takes an array of screen titles instead of a screenPath String: 
```objc
[Optimove.shared setScreenVisitWithScreenPathArray: @[@"Home", @"Store", @"Footware", @"Boots"] screenTitle: @"<YOUR_TITLE>" screenCategory: @"<OPTIONAL: YOUR_CATEGORY>"];
```

- Where:
	 - **screenTitle**: which represent the current scene
	 - **screenPath**: which represent the path to the current screen in the form of 'path/to/scene
	 - **screenCategory**: which adds the scene category it belongs to. 
<br/>

### Optipush (Dynamic Deep Link support)
The `OptimoveDeepLinkComponents` Object has a new property called `parameters` to support dynamic parameters when using deep linking.

`UIViewController` Header Example:
```objc
#import <UIKit/UIKit.h>
@import OptimoveSDK;

@interface MainViewController : UIViewController <OptimoveDeepLinkCallback, OptimoveSuccessStateDelegate>
@property (weak, nonatomic) IBOutlet UILabel *output;


@end
```

`UIViewController` implementation Example:
```objc
@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [Optimove.shared registerWithDeepLinkResponder: [[OptimoveDeepLinkResponder alloc] init: self]];
}

- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents *) deepLink {
    if (deepLink != nil) {
        // Retrieve the targetted screen name
        NSString* screenName = deepLink.screenName;
        // Retrieve the deep link Key-Value parameters
        NSDictionary* deepLinkParams = deepLink.parameters;
    }
}

@end
```

## API Changes

### configure function
1. Changed `Optimove.sharedInstance` to `Optimove.shared`
1. Changed `[Optimove.sharedInstance configureFor: info];` to `[Optimove configureFor: info];` 
2. Removed `url` from `OptimoveTenantInfo`
3. Changed `token` to `tenantToken` in `OptimoveTenantInfo`
4. Changed `version` to `configName` in `OptimoveTenantInfo`
5. Removed `hasFirebase: false,` and `useFirebaseMessaging: false` from `OptimoveTenantInfo` - No need to notify Optimove SDK about your internal 'Firebase' integration as this is done automatically for you.
6. `OptimoveNotificationServiceExtension` is now initialized as follow: `[[OptimoveNotificationServiceExtension alloc] initWithAppBundleId:@"<YOUR_APP_TARGET_BUNDLE_ID>"];`

> 1. If you use the Firebase SDK, add `FirebaseApp.configure()` before `Optimove.configure(for: info)`. Failing to do so when you use the Firebase SDK will cause unexpected behavior and even crashes.
> Example Code Snippet:
> ```objc
> [FirebaseApp configure];
> OptimoveTenantInfo *info = [[OptimoveTenantInfo alloc] initWithTenantToken: @"<YOUR_SDK_TENANT_TOKEN>" configName: @"<YOUR_MOBILE_CONFIG_NAME>"];
> [Optimove configureFor: info];
> ```
> 2. Please request from the Product Integration team your `tenantToken` and `configName` dedicated to your Optimove instance.

<br/>

### User ID function
Aligned all Web & Mobile SDK to use the same naming convention for this function.

- Change from 
```objc
[Optimove.sharedInstance setWithIserId: @"<SDK_ID>"];
```

- To:
```objc
[Optimove.shared setUserId: @"<SDK_ID>"];
```
<br/>

### Update registerUser function
Aligned all Web & Mobile SDK to use the same naming convention for this function.
- Change from 
```objc
[Optimove.sharedInstance registerUserWithEmail: "<MY_EMAIL>" userId: "<MY_SDK_ID>"];
```

- To:
```objc
[Optimove.shared registerUserWithSdkId: @"<SDK_ID>" email: @"<EMAIL>"]
```
<br/>

### Removed the need for custom FirebaseMessaging Delegate
The [Forward Firebase Tokens to Optimove](https://github.com/optimove-tech/iOS-SDK-Integration-Guide#forward-firebase-tokens-to-optimove) is no longer needed. You can remove any code that was handling this step.

### During integration phase only
-   During integration, add the flag `OPTIMOVE_CLIENT_STG_ENV` to your Build Settings as a User-Defined setting. Only for the Build schemas of your **Staging** environment, set the value to `true`. For any other schema, the value **must** be `false`.

In the build Setting of your target, press the `+` button and select `Add User-Defined Setting`
<p align="left"><kbd><img src="https://github.com/optimove-tech/iOS-SDK-Integration-Guide/blob/master/images/user-defined-settings-1.png?raw=true"></kbd></p>
    
- Add `OPTIMOVE_CLIENT_STG_ENV` key with `true` as value for the correct Build Schema.
<p align="left"><kbd><img src="https://github.com/optimove-tech/iOS-SDK-Integration-Guide/blob/master/images/user-defined-settings-2.png?raw=true"></kbd></p>

- In the `info.plist`, add an entry that uses "Build settings placeholder" by setting the value to `$(OPTIMOVE_CLIENT_STG_ENV)` and the key to `OPTIMOVE_CLIENT_STG_ENV`
<p align="left"><kbd><img src="https://github.com/optimove-tech/iOS-SDK-Integration-Guide/blob/master/images/user-defined-settings-3.png?raw=true"></kbd></p>

> This concept is similar to using different Bundle Ids for different App Development lifecycles (.dev/.stg)

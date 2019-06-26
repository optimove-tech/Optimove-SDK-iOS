
# iOS Mobile SDK Changelog v2.0

## Dependencies
* Firebase => 5.20.2
* FirebaseAnalytics => 5.8.1
* FirebaseAnalyticsInterop => 1.2.0
* FirebaseCore => 5.4.1
* FirebaseDynamicLinks => 4.0.0
* FirebaseInstanceID => 3.8.1
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
```swift
Optimove.sharedInstance.reportScreenVisit(viewControllersIdentifiers:url:category:)
```

- To single screen title:
```swift
Optimove.shared.setScreenVisit(screenPath: "Home/Store/Footware/Boots", screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```
- Or an array of screen titles
Added a screen reporting function which takes an array of screen titles instead of a screenPath String: 
```swift
Optimove.shared.setScreenVisit(screenPathArray: ["Home", "Store", "Footware", "Boots"], screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```

- Where:
	 - **screenTitle**: which represent the current scene
	 - **screenPath**: which represent the path to the current screen in the form of 'path/to/scene
	 - **screenCategory**: which adds the scene category it belongs to. 
<br/>

### Optipush (Dynamic Deep Link support)
The `OptimoveDeepLinkComponents` Object has a new property called `parameters` to support dynamic parameters when using deep linking.

Partial code snippet example:
```swift
class ViewController: UIViewController, OptimoveDeepLinkCallback {
    func didReceive(deepLink: OptimoveDeepLinkComponents?)
    {
        guard let deepLink = deepLink else {return}
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "deepLinkVc") as? DeepLinkViewController else { return }

        vc.deepLinkComp = deepLink
        // Retrieve the targetted screen name
        let screenName = deepLink.screenName
        // Retrieve the deep link Key-Value parameters
        let deepLinkParams = deepLink.parameters
        present(vc, animated: true)
    }
}
```

## API Changes

### configure function
1. Changed `Optimove.sharedInstance.configure(for: info)` to `Optimove.configure(for: info)` 
2. Removed `url` from `OptimoveTenantInfo`
3. Changed `token` to `tenantToken` in `OptimoveTenantInfo`
4. Changed `version` to `configName` in `OptimoveTenantInfo`
5. Removed `hasFirebase: false,` and `useFirebaseMessaging: false` from `OptimoveTenantInfo` - No need to notify Optimove SDK about your internal 'Firebase' integration as this is done automatically for you.

> 1. If you use the Firebase SDK, add `FirebaseApp.configure()` before `Optimove.configure(for: info)`. Failing to do so when you use the Firebase SDK will cause unexpected behavior and even crashes.
> Example Code Snippet:
> ```swift
> FirebaseApp.configure()
> let info = OptimoveTenantInfo(tenantToken: "<YOUR_SDK_TENANT_TOKEN>", configName: "<YOUR_MOBILE_CONFIG_NAME>")
> Optimove.configure(for: info)
> ```
> 2. Please request from the Product Integration team your `tenantToken` and `configName` dedicated to your Optimove instance.

<br/>

### User ID function
Aligned all Web & Mobile SDK to use the same naming convention for this function.

- Change from 
```swift
Optimove.sharedInstance.set(userId:)
```

- To:
```swift
Optimove.shared.setUserId("<MY_SDK_ID>")
```
<br/>

### Update registerUser function
Aligned all Web & Mobile SDK to use the same naming convention for this function.
- Change from 
```swift
Optimove.sharedInstance.registerUser(email: "<MY_EMAIL>", userId: "<MY_SDK_ID>")
```

- To:
```swift
Optimove.shared.registerUser(sdkId: "<MY_SDK_ID>", email: "<MY_EMAIL>")
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

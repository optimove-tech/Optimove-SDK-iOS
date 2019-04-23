
# iOS Mobile SDK Changelog v2.0

## Dependencies
1. Firebase 5.20.2
2. includes `FirebaseMessaging` 3.5.0, and `FirebaseDynamicLinks` 3.4.3

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
Aligned all Web & Mobile SDK to use the same naming convention for this function.

- Change from 
```ruby
Optimove.sharedInstance.reportScreenVisit(viewControllersIdentifiers:url:category)
```

- To single screen title:
```ruby
Optimove.shared.setScreenVisit(screenPath: "<YOUR_PATH>", screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```
- Or an array of screen titles
Added a screen reporting function which takes an array of screen titles instead of a screenPath String: 
```ruby
Optimove.shared.setScreenVisit(screenPathArray: ["Home", "Store", "Footware", "Boots"], screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```

- Where:
	 - **screenTitle**: which represent the current scene
	 - **screenPath**: which represent the path to the current screen in the form of 'path/to/scene
	 - **screenCategory**: which adds the scene category it belongs to. 
<br/>

### Optipush
The `OptimoveDeepLinkComponents` Object has a new property called `parameters` to support dynamic parameters when using deep linking.

Code snippet example:
```ruby
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
 1. Change `Optimove.sharedInstance.configure(for: info)` to `Optimove.configure(for: info)` 
 2. Remove `url` from `OptimoveTenantInfo()`
 3. Change `token` to `tenantToken`
 4.  Change `version` to `configName`
 5. Remove `hasFirebase: false,` and `useFirebaseMessaging: false` from `configure()`- No need to notify Optimove SDK about your internal 'Firebase' integration as this is done automatically for you
 6. Add (and call) `FirebaseApp.configure()` before `Optimove.configure(for: info)` 

	Example Code Snippet:
	```ruby
	FirebaseApp.configure()
	let info = OptimoveTenantInfo(
          tenantToken: "<YOUR_SDK_TENANT_TOKEN>",
          configName: "<YOUR_MOBILE_CONFIG_NAME>"
          )
    Optimove.configure(for: info)
	```
	Note: Please request from the Product Integration team your `tenantToken` and `configName` dedicated to your Optimove instance.

<br/>

### User ID function
Aligned all Web & Mobile SDK to use the same naming convention for this function.

- Change from 
```ruby
Optimove.sharedInstance.set(userId:)
```

- To:
```ruby
Optimove.shared.setUserId("<MY_SDK_ID>")
```
<br/>

### Update registerUser function
Aligned all Web & Mobile SDK to use the same naming convention for this function.
- Change from 
```ruby
Optimove.sharedInstance.registerUser(email: "<MY_EMAIL>", userId: "<MY_SDK_ID>")
```

- To:
```ruby
Optimove.shared.registerUser(email: "<MY_EMAIL>", sdkId: "<MY_SDK_ID>")
```
<br/>

### During integration phase only
-   During integration, add the flag  `OPTIMOVE_CLIENT_STG_ENV`  to your user-defined Build settings with value `true`.  
    In the build Setting of your target, press the  `+`  button and select `Add User-Defined Setting`
    <IMAGE1>
    
- Add `OPTIMOVE_CLIENT_STG_ENV` key with `true` as value  
 <IMAGE2>

- In the `info.plist`, add an entry that map to this value  
 <IMAGE3>

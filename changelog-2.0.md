## iOS Mobile SDK Changelog v2.0

### SDK Configurations

Please update the following SDK Details as follows:

 1. **Podfile details**:
	```ruby
	platform :ios, '10.0'
	# Update "target" accordingly to support silent minor upgrades:
	target '<YOUR_TARGET_NAME>' do
	    use_frameworks!
	    pod 'OptimoveSDK',
	    pod 'OptimoveSDK','~> 2.0'
	end

	target 'Notification Extension' do
	    use_frameworks!
	    pod 'OptimoveNotificationServiceExtension', '~> 2.0'
	end
	```

 2. **Firebase Dependency**  
Firebase 5.20.2

 3. **Update configure()**  

	- Change Optimove.sharedInstance.configure(for: info) to Optimove.configure(for: info) 
	- Change "token" to "tenantToken"
	- Change "version" to "configName"
	- Remove from Optimove.configure(for: info) the "hasFirebase: false," and "useFirebaseMessaging: false" - No need to notify Optimove SDK about your internal 'Firebase' integration as this is now done automatically for you
	- Add (and call) **FirebaseApp.configure()** before Optimove.configure(for: info) 

	Example Code Snippet:
	```java
	FirebaseApp.configure()
	let info = OptimoveTenantInfo(
          tenantToken: "your token",
          configName: "mobileconfig.1.0.0"
          )
    Optimove.configure(for: info)
	```

 4. **Mobile Config Name**: request from the Product Integration Team a new version of your mobile config

<br/>

### Update Screen Visit function
Aligned all Web & Mobile SDK to use the same naming convention for this function.

- Change from 
```java
Optimove.sharedInstance.reportScreenVisit(viewControllersIdentifiers:url:category)
```

- To single screen title:
```java
Optimove.shared.setScreenVisit(screenPath: "<YOUR_PATH>", screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```
- Or an array of screen titles
Added a screen reporting function which takes an array of screen titles instead of a screenPath String: 
```java
Optimove.shared.setScreenVisit(screenPath: "<YOUR_PATH>", screenTitle: screenTitleArray, screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```

- Where:
	 - **screenTitle**: which represent the current scene
	 - **screenPath**: which represent the path to the current screen in the form of 'path/to/scene
	 - **screenCategory**: which adds the scene category it belongs to. 

<br/>

### Update User ID function
Aligned all Web & Mobile SDK to use the same naming convention for this function.
- Change from 
```java
Optimove.sharedInstance.set(userId:)
```

- To:
```java
Optimove.shared.setUserId("<MY_SDK_ID>")
```
<br/>

### Update registerUser function
Aligned all Web & Mobile SDK to use the same naming convention for this function.
- Change from 
```java
Optimove.sharedInstance.registerUser(email: "<MY_EMAIL>", userId: "<MY_SDK_ID>")
```

- To:
```java
Optimove.shared.registerUser(email: "<MY_EMAIL>", sdkId: "<MY_SDK_ID>")
```

## iOS Mobile SDK Changelog v2.0

### 1. SDK Configurations

Please update the following SDK Details as follows:

 1. **Podfile details**:
	 - Platform :iOS, '10.0'
	 - Update "target" accordingly to support silent minor upgrades:
	```java
	target 'optimovemobileclientnofirebase' do
	    use_frameworks!
	    pod 'OptimoveSDK',
	pod 'OptimoveSDK','~> 2.0'

	end

	target 'Notification Extension' do
	    use_frameworks!
	    pod 'OptimoveNotificationServiceExtension,'~> 2.0'
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

### 2. Updated Screen Visit function
Aligned all Web & Mobile SDK to use the same naming convenstion for this function.

- Change from 
```java
Optimove.sharedInstance.reportScreenVisit(viewControllersIdentifiers:url:category)
```

- To:
```java
Optimove.shared.setScreenVisit(screenPath: "<YOUR_PATH>", screenTitle: "<YOUR_TITLE>", screenCategory: "<OPTIONAL: YOUR_CATEGORY>")
```
- Where:
	 - **screenTitle**: which represent the current scene
	 - **screenPath**: which represent the path to the current screen in the form of 'path/to/scene
	 - **screenCategory**: which adds the scene category it belongs to. 



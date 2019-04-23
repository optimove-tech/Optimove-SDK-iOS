## iOS Mobile SDK Changelog v2.0

### 1. SDK Configurations

Please update the following SDK Details as follows:

 1. **Podfile details**:
	 a. Platform :iOS, '10.0'
	 b. Update "target" accordingly to support silent minor upgrades:
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

 3. **Removed "hasFirebase" and "useFirebaseMessaging"**  
No need to notify `OptimoveSDK` about your internal 'Firebase' integration as this is not done automatically for you.
	- Remove from Optimove.sharedInstance.configure(for: info) the "hasFirebase: false," and "useFirebaseMessaging: false"
	- Add (and call) **firebaseApp.configure()** before Optimove.shareInstance.configure(for: info) 

	Example Code Snippet:
	```java
		firebaseApp.configure()
		let info = OptimoveTenantInfo(
	          token: "abcdefg12345678",
	          version: "mobileconfig.1.0.0"
	          )
	    Optimove.sharedInstance.configure(for: info)
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
Optimove.sharedInstance.setScreenVisit(viewControllersIdentifiers:screenPath:screenTitle:screenCategory)
```
- Where:
	 - **screenTitle**: which represent the current scene
	 - **screenPath**: which represent the path to the current screen in the form of 'path/to/scene
	 - **screenCategory**: which adds the scene category it belongs to. 



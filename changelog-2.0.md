## iOS SDK Change Log v2.-
### 1. SDK configuration
Please update the following SDK Details as follows:

 1. Mobile Config Name: request from the Product Integration Team
 2. Podfile details:
	 a. Platform :iOS, '10.0'
	 b. Update "target":
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

 3. **Firebase Dependency**  
OptimoveSDK version 2.0.0 depends on Firebase 5.20.2

<br/>
### 2. Enhancement Report Screen Visit function
Enhancement of the public API so it is more convenient to report event using clear parameters like:

 - **screenTitle**: which represent the current scene
 - **ScreenPath**: which represent the path to the current screen in the form of 'path/to/scene
 - **category**: which adds the scene category it belongs to.
 - 
<br/>
### 3. Removed _hasFirebase_ from the `configure` method
Now you don't need to worry about notify `OptimoveSDK` about your internal 'Firebase' integration.
Remove from .....configure(for: info)
This means you first need to call Firebase intiialization and then the Optimove intitialize
Remove hasFirebase
Add:
- **FirebaseApp.configure()** - show some code snippet and make sure its bolder/highlighted
- **Optimove.shareInstance.configure(for: info)**

<br/>
### 4. Removed _hasFirebaseMessaging_ from the `configure` method
Now you don't need to worry aboud notify `OptimoveSDK` about chages in the `fcmToken` since `OptimoveSDK` listen for the changes by itself.


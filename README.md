# Optimove iOS SDK Integration
Optimove's iOS SDK for native apps is a general-purpose suite of tools that is built to support multiple Optimove products.<br>
The SDK is designed with careful consideration of the unpredicted behavior of the Mobile user and Mobile environment, taking into account limited to no networking and low battery or memory limitations.<br>
While supporting a constantly rising number of products, the SDK's API is guaranteed to be small, coherent and clear.
This is a developers’ guide for integrating the native Optimove mobile SDK with native iOS applications.

This guide covers the basic technical steps for configuring and installing the SDK,
demonstrate common use cases, and provide usage guidelines.

## Getting Started
There are a few important steps to get out of the way when integrating Optimove SDK with your app for the first time.<br>

Please follow these instructions carefully to ensure that you’ll have an easy development experience.<br>

### Prerequisites

Before you can begin using Optimove SDK for iOS, you will need to
perform the following steps.</br>

* A *tenant_information_suite* provided during the initial integration with Optimove and contains the following:
        `end-point url` - The URL where the **_tenant configurations_** reside
        `token` - The actual token, unique per tenant
        `config name` - The name of the desired configuration
* Tenant has a paid development account, and valid certificates for remote notifications or APN Auth key.
* Deliver The APN Auth key (preferred) or APN Certificates was delivered to Optimove CSM.
* Deliver the Team ID
* Deliver the Appstore ID of the application
* Enable push notification and remote notification capabilities in your project

[![apple_dashboared.png](https://s9.postimg.org/9ln5sfxe7/apple_dashboared.png)](https://postimg.org/image/itfe954gb/)
 

## Setting up the SDK
Optimove SDK for iOS is provided as a group of files within a Folder named “OptimoveSDK”.<br>

To install the SDK, drag the folder into your project. <br>

If not all files inside the folder are members of the target application, add them.<br>

In order to work with the Optimove SDK, you also need to download some modules from CocoaPods. <br>
In your Podfile, add the following:

````swift
pod 'Firebase','~> 4.8.0'
pod 'FirebaseMessaging', '~> 2.0.8'
pod 'FirebaseDynamicLinks', '~> 2.3.1'
pod 'XCGLogger', '~> 6.0.2'
pod 'OptimovePiwikTracker'
````

In your AppDelegate class, inside the
````swift
application (_: didFinishLaunchingWithOptions:)
````
method, create a new `OptimoveTenantInfo` object.
This object should cotain:<br>
1. The end-point URL<br>
2. Unique Optimove token.<br>
3. Configuration key provided by Optimove CSM<br>
4. Indication for exsiting Firebase module inside your application.<br>

Use this Object as an argument for the SDK Function
```swift
 Optimove.sharedInstance.configure(info:) 
```
This call initializes the _`OptimoveSDK`_ Singleton.

for example:
````swift
func application(_ application: UIApplication,
didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
let info = OptimoveTenantInfo(url:"https://optimove.mobile.demo/sdk-configs/", // end-point url
token: "abcdefg12345678", // token
version: "myapp.ios.1.0.0", //config name
hasFirebase: false) // indication for tenant autonomous firebase
Optimove.sharedInstance.configure(info: info)
````

The initialization must be called **as soon as possible**, unless the tenant has its own Firebase SDK.
In this case start the initialization right after calling  `FirebaseApp.configure()`.

## State Registration

The SDK initialization process occurs asynchronously, off the `Main Thread`.<br>
Before calling the Public API methods, make sure that the SDK has finished initialization by calling the _`register(stateDelegate:)`_ method with an instance of _`OptimoveStateDelegate`_.<br>

```swift
class AppDelegate: UIResponder,
    UIApplicationDelegate, OptimoveStateDelegate
  {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {    
        let info = OptimoveTenantInfo(url:"https://optimove.mobile.demo/sdk-configs/",
                                      token: "abcdefg12345678",
                                      version: "myapp.ios.1.0.0",
                                      hasFirebase: false)
        
        Optimove.sharedInstance.configure(info: info)
        Optimove.sharedInstance.register(stateDelegate: self)
        return true
    }
  }
```
Do not forget to implement the _`OptimoveStateDelegate`_ methods, and provide a unique Int id to any enitity that conform to the protocol.

## Reporting User Activities and Events
Using the Optimove's iOS SDK, the hosting application can track events with analytical significance.<br>
These events can range from basic _**`Screen Visits`**_ to _**`Visitor Conversion`**_ and _**`Custom Events`**_ defined in the `Optimove Configuration`.<br>
If you want to use optitrack capabilities as your analytics tool, you may use Optimove API such as:

### Set User ID
Once the user has downloaded the application and the _Optimove SDK_ run for the first time, the user is considered a _Visitor_, i.e. an unidentified person.<br>
Once the user authenticates and becomes identified by a known `PublicCustomerId`, then the user is considered _Customer_.<br>
As soon as this happens for each individual user, pass the  `CustomerId` to the `Optimove` singleton like this: <br>
```swift
Optimove.sharedInstance.set(userId:)
```

>Note: the `CustomerId` is usually provided by the Server App that manages customers, and is the same ID provided to Optimove during the daily customer data transfer.<br>
>
>Due to its high importance, `set (userId:)` may be called at any time, regardless of the SDK’s state.

### Report Screen Event
To track which screens the user has visited in your app, send a _setScreenEvent_ message to the shared Optimove instance:.<br>

````swift
Optimove.sharedInstance.setScreenEvent(viewControllersIdentifiers:url)
````
The _`viewControllersIdentifiers`_ argument should include an array that represents the path to the current screen.<br>
To support more complex view hierarchies, you may also specify a screen URL in the second parameter.<br>

### Report Custom Event
To report a _**`Custom Event`**_ (one defined by you and the Optimove Integration Team and already configured in your Optimove site), you must implement the `OptimoveEvent` protocol.<br>
The protocol defines 2 properties:
1. `name: String` - Declares the custom event's name
2. `parameters: [String:Any]` - Defines the custom event's parameters.<br>
Then send that event through the `reportEvent(event:)` method of the `Optimove` singleton.

````swift
override func viewDidAppear(_ animated: Bool) {
super.viewDidAppear(animated)
Optimove.sharedInstance.reportEvent(event: MyCustomEvent())
}
````
>Note:<br>
* All _**`Custom Event`**_ must be declared in the _Tenant Configurations_. <br>
* _**`Custom Event`**_ reporting is only supported when OptiTrack Feature is enabled.<br>
*  The usage of `reportEvent` function depends on your needs.<br>
This function may include a completion handler that will be called once the report has finished, the default value for this argument is nil.


## Optipush:
_*Optipush*_ is Optimove’s mobile push notification delivery add-in module, powering all aspects of preparing, delivering and tracking mobile push notification communications to customers, seamlessly from within Optimove.<br> _*Optimove SDK*_ for iOS includes built-in functionality for receiving push messages, presenting notifications in the app UI and tracking user responses.

In order for Optipush to be able to deliver push notifications to your iOS app, Optimove SDK for iOS must receive an APN token from your app. This is accomplished by the following  steps:
Inside the application `AppDelegate` class <br>
````swift
application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
````
call <br>

````swift
 Optimove.sharedInstance.application(didRegisterForRemoteNotificationsWithDeviceToken:)
````
And  in <br>
````swift
application(_:didReceiveRemoteNotification:fetchCompletionHandler:)
````
 call <br>
````swift
 Optimove.sharedInstance.handleRemoteNotificationArrived(userInfo:fetchCompletionHandler)
````

 example:<br>
````swift
 
  func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        Optimove.sharedInstance.handleRemoteNotificationArrived(userInfo: userInfo,
                                                        fetchCompletionHandler: completionHandler)
      
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
    {
        Optimove.sharedInstance.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
 
````

## Deep Link:

Other than _UI attributes_, an **_Optipush Notification_** can contain metadata linking to a specific screen within your application, along with custom (screen specific) data.<br>

To support deep linking, you should:

* Enable Associated Domains:
In your project capabilities, add the dynamic link domain with `applinks:` prefix and without any `https://` prefix

[![associated_domain.png](https://s9.postimg.org/hqrw4eqm7/associated_domain.png)](https://postimg.org/image/3x3jfcy0r/)
<br>
Any  _`ViewControler`_ should recieve DynamicLink data callback, should implement _`didReceive(dynamicLink:)`_, thus conforming to _`DynamicLinkCallback`_ protocol .<br>
_`DynamicLinkCallback`_ protocol has one method:
````swift
didReceive(dynamicLink:)
````

A dynamicLinkComponent struct contains two properties:

· ScreenName: for the required _*viewcontroller*_ you need to segue to.

· Query: That contain the content that should be included in that view controller.

example:
````swift
func didReceive(deepLink: OptimoveDeepLinkComponents?) {
    if let deepLink = deepLink {
    DispatchQueue.main.asyncAfter(deadline: .now()+2.0)
    {
        if let vc = self.storyboard?.instantiateViewController(withIdentifier: deepLink.screenName) {
            self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }
}
````

### Test Optipush Templates
t is usually desirable to test an **_Optipush Template_** on an actual device before sending an **_Optipush Campaign_** to users.<br>
To enable _"test campaigns"_ on one or more devices, call the _**`Optimove.sharedInstance.subscribeToTestMode()`**_ method.<br>
To stop receiving _"test campaigns"_ call  _**`Optimove.sharedInstance.unSubscribeFromTestMode()`**_.<br>

````swift
class ViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Optimove.sharedInstance.subscribeToTestMode()                              
    }
}
````

## Special Use Cases

### The Hosting Application Uses Firebase

#### Installation

The _Optimove iOS SDK_ is dependent upon the _Firebase iOS SDK_.<br>
If your application already uses **_Firebase SDK_** or has a dependency with **_Firebase SDK_**, a build conflict or  runtime exception may occur,  due to backwards compatibility issues.<br>
Therefor, it is highly recommended to match the application's **_Firebase SDK version_** to Optimove's **_Firebase SDK version_** as detailed in the following table.


| Optimove SDK Version | Firebase Version | Firebase Messaging Version | FirebaseDynamicLinks |   
| --- | --- | --- | --- | 
| 1.0.2                | 4.8.0            | 2.0.8                      | 2.3.1                |

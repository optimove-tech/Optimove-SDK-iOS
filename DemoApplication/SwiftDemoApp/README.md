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

* A *tenant_information_suite* provided during the initial integration with Optimove and contains the following:
        `end-point url` - The URL where the **_tenant configurations_** reside
        `token` - The actual token, unique per tenant
        `config name` - The name of the desired configuration
* Tenant has a paid development account, and valid certificates for remote notifications or APN Auth key.
* The APN Auth key (preferred) or APN Certificates was delivered to Optimove CSM.
* Enable push notification and remote notification capabilities in your project

[![apple_dashboared.png](https://s9.postimg.org/9ln5sfxe7/apple_dashboared.png)](https://postimg.org/image/itfe954gb/)
 

## Installation

There are two options to setup the SDK:<br>
 **Manually**:<br>
The SDK is provided as a group of files, sitting inside a Folder name “Optimove”.

Drag the folder inside your project.

Verify that all the files inside the folder members of the target application, if not add them.

**Git Submodule**:<br>
The SDK is provided through GitHub repository and should be added as submodule to your project, for any release updates in the submodule, that will be tagged, you need to pull it and add the updated files to the project.

## SDK Setup:<br>
In your AppDelegate class, inside method
 ```swift 
application (_: didFinishLaunchingWithOptions:)
```
Create a new `OptimoveTenantInfo` object.
> Note:this object should cotain:<br>
>1. Optimove Unique token.<br>
>2. Configuration key provided by Optimove CSM<br>
>3. Indication for exsiting Firebase module inside your application.

Use this Object as an argument for the SDK Function
 ```swift 
 Optimove.sharedInstance.configure(info:) 
```
This call would initialize the `OptimoveSDK` Singleton.

for example:
```swift
func application(_ application: UIApplication,
didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
let info = OptimoveTenantInfo(url:"https://optimove.mobile.demo/sdk-configs/", // end-point url
token: "abcdefg12345678", // token
version: "myapp.ios.1.0.0", //config name
hasFirebase: false) // indication for tenant autonomous firebase
Optimove.sharedInstance.configure(info: info);
```

The initialization must be called **as soon as possible**, unless the tenant has its own Firebase SDK.
In this case start the initialization right after calling FirebaseApp.configure().

## State Registration

The SDK initialization process occurs asynchronously, off the `Main Thread`.<br>
Before calling the Public API methods, make sure that the SDK has finished initialization by calling the _`register(stateDelegate:)`_ method with an instance of _`OptimoveStateDelegate`_.<br>

```swift
class AppDelegate: UIResponder,
    UIApplicationDelegate, OptimoveStateDelegate
  {
    var window: UIWindow?
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool 
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

## Analytics
Using the Optimove's iOS SDK, the hosting application can track events with analytical significance.<br>
These events can range from basic _**`Screen Visits`**_ to _**`Visitor Conversion`**_ and _**`Custom Events`**_ defined in the `Optimove Configuration`.<br>If you want to use optitrack capabilities as your analytics tool, you may use Optimove API such as:

### Set User ID
Once the user has downloaded the application and the SDK run for the first time, the user is considered a _Visitor_, an unknown user.<br>
At a certain point the user will authenticate and will become identified by a known `PublicCustomerId`, then the user is considered _Customer_.<br>
Pass that `CustomerId` to the `Optimove` singleton as soon as the authentication occurs.<br>
>Note: the `CustomerId` is usually delivered by the Server App that manages customers, and is integrated with Optimove Data Transfer.<br>
>
>Due to its high importance, `set (userId:)` can be called at any given moment, regardless of the SDK's state.
```swift
Optimove.sharedInstance.set(userId:)
```
### Report Screen Event
To target which screens the user has visited in the app, create a new `ScreenName` event with the appropriate `screenName` and pass it to the `Optimove` singleton.
```swift
Optimove.sharedInstance.reportEvent(event: ScreenName(screenName: "report event screen"))
```
### Report Custom Event
To create a _**`Custom Event`**_ (not provided as a predefined event by Optimove) implement the `OptimoveEvent protocol`.<br>
The protocol defines 2 properties:
1. `name: String` - Declares the custom event's name
2. `parameters: [String:Any]` - Defines the custom event's parameters.
Then send that event through the `reportEvent(event:)` method of the `Optimove` singleton.
>Note: Any _**`Custom Event`**_ must be declared in the _Tenant Configurations_. <br>
_**`Custom Event`**_ reporting is only supported when OptiTrack Feature is enabled.

```swift
override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Optimove.sharedInstance.reportEvent(event: MyCustomEvent())
    }
```
>Note: The usage of `reportEvent` function depends on your needs.<br>
This function may include a completion handler that will be called once the report has finished, the default value for this argument is nil.


## Optipush:

Optimove SDK provides Push Notification support.<br>
A Prerequsite for the Push Notiication support is to receive APNs token from the developer.

### Support the Token Delivery to the Optimove SDK using the following steps:
Inside the application `AppDelegate` class
 ```swift 
application(_:didRegisterForRemoteNotificationsWithDeviceToken:)
``` 
call
 ```swift 
 Optimove.sharedInstance.application(didRegisterForRemoteNotificationsWithDeviceToken:)
 ```
And  in
```swift
application(_:didReceiveRemoteNotification:fetchCompletionHandler:)
```
 call 
 ```swift
 Optimove.sharedInstance.handleRemoteNotificationArrived(userInfo:fetchCompletionHandler)
 ```

 example:
 ```swift
 
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
 
 ```

## Deep Link:

Other than _UI attributes_, an **_Optipush Notification_** can contain metadata that can lead the user to a specific screen within the hosting application, alongside custom (screen specific) data.<br>
To support deep linking, you should:

* Enable Associated Domains:
In your project capabilities, add the dynamic link domain with `applinks:` prefix and without any `https://` prefix

[![associated_domain.png](https://s9.postimg.org/hqrw4eqm7/associated_domain.png)](https://postimg.org/image/3x3jfcy0r/)
<br>
Any  _`ViewControler`_ should recieve DynamicLink data callback, should implement _`didReceive(dynamicLink:)`_, thus conforming to _`DynamicLinkCallback`_ protocol .<br>
_`DynamicLinkCallback`_ protocol has one method:
```swift
didReceive(dynamicLink:)
```

A dynamicLinkComponent struct contains two properties:

· ScreenName: for the required viewcontroller you need to segue to.

· Query: That contain the content should be included in that view controller.

example:
```swift
 func didReceive(dynamicLink: DynamicLinkComponents?)
    {
        guard let dynamicLink = dynamicLink else {return}
        switch dynamicLink.screenName {
        case "required_screen":
            guard let vc = dynamicLink.query["id"] else {return}
                self.navigationController?.pushViewController(vc, animated: true)
        default:
            return
        }
    }
```

### Test Optipush Templates
It might be desired to test an **_Optipush Template_** on an actual device before creating an **_Optipush Campaign_**. To enable _"test campaigns"_ on one or more devices, call the _**`Optimove.sharedInstance.subscribeToTestMode()`**_ method. To stop receiving _"test campaigns"_ call the _**`Optimove.sharedInstance.unSubscribeFromTestMode()`**_.

```swift
class ViewController: UIViewController {
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Optimove.sharedInstance.subscribeToTestMode()                              
    }
}
```

## Special Use Cases

### The Hosting Application Uses Firebase

#### Installation

The _Optimove iOS SDK_ is dependent upon the _Firebase iOS SDK_.<br>
If the application into which the **_Optimove iOS SDK_** is integrated already uses **_Firebase SDK_** or has a dependency with **_Firebase SDK_**, a build conflict might occur, and even **Runtime Exception**, due to backwards compatibility issues.<br>
Therefor, it is highly recommended to match the application's **_Firebase SDK version_** to Optimove's **_Firebase SDK version_** as detailed in the following table.


| Optimove SDK Version | Firebase Version | Firebase Messaging Version | FirebaseDynamicLinks |   
| --- | --- | --- | --- | 
| 1.0.0                | 4.8.0            | 2.0.8                      | 2.3.1                |
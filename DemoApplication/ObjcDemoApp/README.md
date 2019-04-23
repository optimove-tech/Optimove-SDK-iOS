# Optimove SDK for iOS

### Introduction

Optimove's iOS SDK for native apps is a general-purpose suite of tools that is built to support multiple Optimove products.</br>
The SDK is designed with careful consideration of the unpredicted behavior of the Mobile user and Mobile environment, taking into account limited to no networking and low battery or memory limitations.</br>
While supporting a constantly rising number of products, the SDK's API is guaranteed to be small, coherent and clear.
This is a developers’ guide for integrating the native Optimove mobile SDK with native iOS applications.

This guide covers the basic technical steps for configuring and installing the SDK,
demonstrate common use cases, and provide usage guidelines.

### Prerequisites

The deployment target for integrating the _*OptimoveSDK*_ should be at least  _*10.0*_. </br>

Before you can begin using Optimove SDK for iOS, you will need to
perform the following steps.

1.  Acquire a *tenant\_information\_suite* from the Optimove
    Integration Team. This contains:

    1.  _`end-point url`_ – The URL where the tenant configurations reside

    2.  _`token`_ – The actual token, unique per tenant

    3.  _`config name`_ – The version of the desired configuration

2.  Acquire a paid development account and valid certificates for remote
    notifications or APN Auth key.

3.  Deliver the following information to your Optimove Customer Success Manager (CSM):</br>
* APN Auth key:</br>
                    1.   In your developer account, go to Certificates, Identifiers & Profiles, and under Keys, select All.</br>
                    2.  Click the Add button (+) in the upper-right corner.</br>
                    3. Enter a description for the APNs Auth Key</br>
                    4. Under Key Services, select the APNs checkbox, and click Continue.</br>
                    5. Click Confirm and then Download. Save your key in a secure place.</br>
                    6. Remember Not to rename the file.</br>
* Team ID</br>
* App Store ID </br>

4.  Enable push notifications and remote notification capabilities in your project (this step is required only for sending push notifications using Optipush).
5.  The app's `Deployment Target` is at least iOS **10.0**

[![apple_dashboared.png](https://s9.postimg.cc/9ln5sfxe7/apple_dashboared.png)](https://postimg.org/image/itfe954gb/)

## Setting Up the SDK

Optimove SDK for iOS is provided as a group of files within a folder named _`OptimoveSDK`_. This folder can be found in [this GitHub repository](https://github.com/optimoveintegrationmobile/ios-sdk/tree/master/DemoApplication/ObjcDemoApp).</br>
To install the SDK, drag this folder into your project. If not all files inside the folder are members of the target application, add them.< /br>

In order to work with the Optimove SDK, you also need to download some modules from CocoaPods. In your Podfile, add the following: </br>

pod 'Firebase', '~> 4.11.0' </br>
pod 'FirebaseMessaging',  '~> 2.1.1' </br>
pod 'FirebaseDynamicLinks',  '~> 2.3.2' </br>
pod 'XCGLogger',  '~> 6.0.2' </br>
pod 'OptimovePiwikTracker' </br>
**Important**: For any Header file that uses the Optimove SDK, add an import with your module name followed by '-Swift.h', such as
````objective-c
#import "HelloWorld-Swift.h" </br>
````
In your AppDelegate class, inside the application (_: didFinishLaunchingWithOptions: ) method, create a new OptimoveTenantInfo object. This object should contain: </br>

1. The end-point URL
2. Unique Optimove token
3. The configuration key provided by your CSM
4. Indication for existing Firebase module inside your application

Use this object as an argument for the SDK function:

````objective-c
[Optimove.sharedInstance configureWithInfo:info];
````

This call initializes the OptimoveSDK singleton. For example:

````objective-c
- (BOOL)application:(UIApplication \*)application
didFinishLaunchingWithOptions:(NSDictionary \*)launchOptions {

// Override point for customization after application launch.

OptimoveTenantInfo \*info = \[\[OptimoveTenantInfo alloc\]
initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com"
token:@"demo\_apps" version:@"1.0.0" hasFirebase:NO\];

\[Optimove.sharedInstance configureWithInfo:info\];
````

The initialization must be called *as soon as possible*, unless the
tenant has its own Firebase SDK. In this case, start the initialization
right after calling \[FIRApp configure\]

## State Registration

The SDK initialization process occurs asynchronously, off the `Main Thread`.</br>
Before calling the Public API methods, make sure that the SDK has finished initialization by calling the _` Optimove.sharedInstance registerWithStateDelegate:`_ method with an instance of _`OptimoveStateDelegate`_.</br>

````objective-c

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
// Override point for customization after application launch.
OptimoveTenantInfo *info = [[OptimoveTenantInfo alloc] initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com"
token:@"demo_apps"
version:@"1.0.0"
hasFirebase:NO];
[Optimove.sharedInstance configureWithInfo:info];
[Optimove.sharedInstance registerWithStateDelegate:self];

return YES;
}


@synthesize optimoveStateDelegateID;

- (void)didBecomeActive {
NSLog(@"did become active");
}

- (void)didStartLoading {
NSLog(@"did become loading");
}

- (void)didBecomeInvalidWithErrors:(NSArray<NSNumber *> * _Nonnull)errors {
NSLog(@"did become invalid");
}
````

Do not forget to implement the _`OptimoveStateDelegate`_ methods, and provide a unique Int id to any enitity that conform to the protocol.

This Id should be a positive _*Int*_.


### If Your App Already Uses Firebase

The Optimove iOS SDK is dependent upon the Firebase iOS SDK. If your app
already uses Firebase SDK or has a dependency with Firebase SDK, a build
conflict or runtime exception may occur, due to backward compatibility
issues. Therefore, it is highly recommended to match the application’s
Firebase SDK version to Optimove’s Firebase SDK:

| **Optimove SDK Version ** | **Firebase Core Version ** | **Firebase Messaging Version ** | **FirebaseDynamicLinks** |
|---------------------------|----------------------------|---------------------------------|--------------------------|
| 1.0.5.1                     | 4.11.0                      | 2.1.1                           | 2.3.2                    |

### Reporting User Activities and Events 

Use Optimove SDK for iOS to report all relevant user actions and
user-specific events to Optimove for realtime tracking and analysis by
[Optitrack](https://docs.optimove.com/implementing-optitrack-website-visitor-tracking/).
Actions and events can include things like logged in, logged out,
registered, visited screen, pushed button, added to cart, initiated
checkout, completed checkout, won game, lost game and made deposit.

Beyond a core set of standard events (which can be seen
[here](https://docs.optimove.com/optimove-sdk/#defining)), the specific
actions and events that can be reported by your app must be
pre-determined by you in conjunction with the Optimove Integration Team,
who will configure your Optimove site to be able to process the defined
events. Contact your CSM for more information.

### Setting the User ID

Once the user has downloaded the application and the Optimove SDK for
iOS has run for the first time, the user is considered a *visitor*,
i.e., an unidentified person.

Once the user authenticates and becomes identified by a known
PublicCustomerId, then the user is considered a *customer*. As soon as
this happens for each individual user, pass the CustomerId to the
Optimove singleton like this:

\[Optimove.sharedInstance setWithUserID:@"John Doe"\];

Note: The CustomerId is usually provided by the server application that
manages customers, and is the same ID provided to Optimove during the
daily customer data transfer. Due to its high importance, set (userId: )
may be called at any time, regardless of the SDK’s state.

### Reporting a Screen Visit Event

To track which screens the user has visited in your app, send a
setScreenEvent message to the shred Optimove instance:

\[Optimove.sharedInstance
setScreenEventWithViewControllersIdetifiers:@\[@"vc1",@"vc2"\]
url:nil\];

### *The viewControllersIdentifiers argument should include an array that represent the path to the current screen* *to support more complex view hierarchies.* *you can also set a* *URL* *of the screen in the second* *parameter.*

### Reporting a Custom Event

To report a custom event (one defined by you and the Optimove
Integration Team and already configured in your Optimove site), you must
implement the OptimoveEvent protocol.

This protocol defines two properties:

1. name: String – Declares the custom event’s name

2. parameters: \[String:Any\] – Specifies the custom
    event’s parameters.

Then, send that event through the reportEvent(event: ) method of the
Optimove singleton:
````objective-c
- (IBAction)userPressOnSend:(UIButton *)sender {
    NSString* stringInput = _stringTextField.text;
    NSNumber* numberInput = @([_numberTextField.text intValue]);
    CombinedEvent* event = [[CombinedEvent alloc] initWithStringInput:stringInput andNumberInput:numberInput];
    [Optimove.sharedInstance reportEventWithEvent:event completionHandler:nil];
}
````

Notes:

* As already mentioned, all custom events must be pre-defined in your
    Tenant Configurations by the Optimove Integration Team.

* Reporting of custom events is only supported when you have purchased
    the
    [Optitrack](https://docs.optimove.com/implementing-optitrack-website-visitor-tracking/)
    add-in module is enabled.

* The usage of the reportEvent function depends on your needs. This
    function may include a completion handler that will be called once
    the report has finished. The default value for this argument is nil.

## Delivering Push Notifications

Optipush is Optimove’s mobile push notification delivery add-in module,
powering all aspects of preparing, delivering and tracking mobile push
notification communications to customers, seamlessly from within
Optimove. Optimove SDK for iOS includes built-in functionality for
receiving push messages, presenting notifications in the app UI and
tracking user responses.

In order for Optipush to be able to deliver push notifications to your
iOS app, Optimove SDK for iOS must receive an APN token from your app.
This is accomplished by the following two steps:

1. Inside the application’s AppDelegate class

```objective-c
    application:didRegisterForRemoteNotificationsWithDeviceToken:
````

, call

````objective-c
    [Optimove.sharedInstance applicationWithdidRegisterForRemoteNotificationsWithDeviceToken:];
````

2. In

````objective-c
application(\_:didReceiveRemoteNotification:fetchCompletionHandler: )
````

call

````objective-c
    [Optimove.sharedInstance
    handleRemoteNotificationArrived:fetchCompletionHandler];
````

For example:

````objective-c
- (void) application:(UIApplication \*)application
didReceiveRemoteNotification:(NSDictionary \*)userInfo
fetchCompletionHandler:(void
(^)(UIBackgroundFetchResult))completionHandler {

\[Optimove.sharedInstance
handleRemoteNotificationArrivedWithUserInfo:userInfo
fetchCompletionHandler:completionHandler\];

}

- (void) application:(UIApplication \*)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData \*)deviceToken
{

\[Optimove.sharedInstance
applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken\];

}
````

### Deep Linking Notifications to a Particular App Screen

Other than UI attributes, an Optipush notification <span
id="_Hlk502568927" class="anchor"></span>may also contain metadata
linking to a specific screen within your app, along with custom
(screen-specific) data.

To support deep linking, enable Associated Domains. To do so: In your
project capabilities, add the deep link domain (provided by Optimove
CSM) with the applinks: prefix and without any https:// prefix.

[![associated_domain.png](https://s9.postimg.cc/hqrw4eqm7/associated_domain.png)](https://postimg.org/image/3x3jfcy0r/)

Any ViewController should receive a DeepLink data callback, and should
implement didReceive(deepLink: ), thus conforming to the DeepLinkCallback
protocol.

The DeepLinkCallback protocol has one method:

> didReceive(deepLink: )

The deepLinkComponent structure contains two properties:

-   **ScreenName** – for the required ViewController you need to segue
    to

-   **Query** – contains the content that should be included in that
    view controller

For example:

````objective-c
- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents \*)deepLink
{

ViewController\* vc = \[\[ViewController alloc\]
initWithNibName:deepLink.screenName bundle:nil\];

\[\[self navigationController\] pushViewController:vc animated:true\]; }
````objective-c

### Testing Push Notification Templates

It is usually desirable to test an Optipush push notification template
on an actual device before sending an Optipush campaign to users.

To enable “test campaigns” on one or more devices, call the
\[Optimove.sharedInstance subscribeToTestMode\]\`method.

To stop receiving “test campaigns,” call \[Optimove.sharedInstance
unSubscribeFromTestMode\].

```objective-c
-(void)viewDidAppear:(BOOL)animated {

\[super viewDidAppear:animated\];

\[Optimove.sharedInstance subscribeToTestMode\];

}
```

In order to test a push notification template, the marketer can send a
test push notification campaign from within Optimove (using the Optipush
UI). Notifications from such a campaign will only be delivered to
devices running the version of your app in which the above “test
campaigns” method was called.


- [Introduction](#Introduction)
- [Basic Setup](#Basic%20Setup)
- [Advanced Setup](#Advanced%20Setup)
-   [Track](#Track)
	-   [Stitching App Visitors to Registered Customer IDs](#Stitching%20Visitors%20to%20Users)
	-   [Tracking Screen Visits](#Tracking%20a%20Screen%20Visit)
	-   [Tracking Custom Events](#Tracking%20Custom%20Events)
-   [Trigger](#Trigger)
 	- [Executing via Optimail](#trigger-optimail)
	- [Executing via Optimove APIs](#trigger-api)
	<br>

# <a id="Introduction"></a> Introduction

Marketers use the [Optimove Relationship Marketing Hub](https://www.optimove.com/product) to automate the execution of highly-personalized customer communications. Optimove offers its clients an efficient way to report data from their websites and trigger campaigns accordingly.

This guide will show you how to setup the iOS (Objective-C) SDK in order to:

 - Track visitor and customer actions and events
 - Trigger Realtime campaigns


# <a id="Basic Setup"></a> Basic Setup

## **Request a Mobile SDK from Optimove**

Before implementing the Optimove Track & Trigger to track visitor / customer activities or perform other functions ([Optipush](https://github.com/optimove-tech/Optipush-Guide)), you will need to contact your Optimove Customer Success Manager (CSM) or Optimove point of contact. <br>
To get started, please follow these instructions: 

### 1. Pre-requisites <br>

1. You have a paid development account for your iOS app, and valid certificates for remote notifications or APN Auth key.
2. The app's Deployment Target is at least iOS 10.0
3. Your Cocoapods version is 1.5 or above
4. You have a Firebase version of 5.4.0 (Optimove SDK is dependent on Firebase version 5.4.0)


### 2. Provide your iOS app details: <br>

Send the following information to your CSM or Optimove POC with your request for your Mobile SDK configuration details in order to incorporate into your iOS app :<br>

1.	***Auth key*** (with its key id) P8 format
2.	***Bundle ID*** (If you are using multiple apps for development/testing purposes, please provide a list of all bundle IDs being used for all environments.)
3.	***Team ID*** (from apple developer dashboard)
4.	***App Store ID*** (from itunesconnect)<br>
  

### 3. Retrieve *OptimoveTenantInfo* details: <br>


After providing the info above, you will receive a *OptimoveTenantInfo* from the Optimove Product Integration Team that contains:<br>
1.	***End-point URL*** – The URL where the tenant configurations reside
2.	***Unique Optimove token*** – The actual token, unique per tenant
3.	***Configuration name*** – The version of the desired configuration

For a demo application containing the iOS SDK, please use our [iOS GitHub repository](https://github.com/optimove-tech/iOS-SDK-Integration-Guide/tree/master/DemoApplication/ObjcDemoApp).

    

## Setting up the iOS SDK

### 1. Install the SDK 
In your Application Target Capabilities: 
1. Enable `push notifications` capabilities <br>
2. Enable`remote notifications` capabilities in`Background Modes`

[![apple_dashboared.png](https://s9.postimg.cc/9ln5sfxe7/apple_dashboared.png)](https://postimg.org/image/itfe954gb/)



### 2.  Download *OptimoveSDK* pod
In order to work with the Optimove SDK for your iOS native app, need to download its module from CocoaPods.

1. In your Podfile, add the following:

`pod OptimoveSDK`

Since _`OptimoveSDK`_ is written in `swift`, you must add `use_modular_headers!` globaly.


Example:
```ruby
platform :ios, '10.0'
use_modular_headers!

target 'iOSDemo' do
  pod 'OptimoveSDK'
end
```

Also, Add an additional 'dummy' swift file to your project in order to enable proper compilation of the workspace.

2. `OptimoveSDK` relies on other modules as infrastructure, such as `Firebase`, so when you download `OptimoveSDK` you get the following frameworks:

* `Firebase/Core` version `5.4.0`
* `Firebase/Messaging`
* `Firebase/DynamicLinks`


### 3. If you are using Optipush, see additional configurations [here](https://github.com/optimove-tech/Optipush-Guide/tree/master/Opitpush%20for%20iOS)  
    
### 4. Run the SDK

In your `AppDelegate` class, inside the callback
  `(BOOL)application: didFinishLaunchingWithOptions:launchOptions` method, create a new `OptimoveTenantInfo` object. This object should contain:

1. The end-point URL
2. Unique Optimove token
3. The configuration version provided by the Optimove Integration Team
4. Indication for existing Firebase module inside your application
5. Indication for using your own `Firebase/Messaging`

For example:

```smalltalk
 OptimoveTenantInfo* info = [[OptimoveTenantInfo alloc] initWithUrl:@"https://optimove-cdn.com" token:@"demo_apps" version:@"1.0.0" hasFirebase:NO useFirebaseMessaging:NO];
```

Use this object as an argument for the SDK function,

 ```smalltalk
   [Optimove.sharedInstance configureFor:]
```  
This call initializes the OptimoveSDK singleton.

6. You should register for notification certificate from APNs using `[UIApplication.sharedApplication registerForRemoteNotifications];`

>Note: It is necessary to `@import OptimoveSDK;` in any file that uses `OptimoveSDK` API 

<br>

For example:
```smalltalk
#import "AppDelegate.h"
#import <UserNotifications/UserNotifications.h>
@import OptimoveSDK;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    OptimoveTenantInfo* info = [[OptimoveTenantInfo alloc] initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com" token:@"demo_apps" version:@"1.0.0" hasFirebase:NO useFirebaseMessaging:NO];
    
    [Optimove.sharedInstance configureFor:info];
    [UIApplication.sharedApplication registerForRemoteNotifications];
    return YES;
}
```
>Note : The initialization **must** be called as soon as possible, unless you have your own _Firebase SDK_. In this case, call `[Optimove.sharedInstance configureFor:];` right after calling `[FIRApp configure];`.


Still in `AppDelegate`, please implement the following callbacks:

```smalltalk
// Called when the OS generates an APNs token
- (void) application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [Optimove.sharedInstance applicationWithDidRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}


// Called when a push message is received by the OS and forwarded to the app's process (used for Optimove analytical purposes)
- (void) application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Forward the callback to the Optimove SDK
    if (![Optimove.sharedInstance didReceiveRemoteNotificationWithUserInfo:userInfo didComplete:completionHandler]) {
        // The push message was not targeted for Optimove SDK. Implement your logic here or leave as is. 
        completionHandler(UIBackgroundFetchResultNewData);
    }
}
```

>Note: If your using you own 'FirebaseMessaging' (a.k.a you enter "true" on the 'useFirebaseMessaging' argument), you must notify Optimove for any changes in the `fcmToken` via calling 
`optimoveWithDidReceiveFirebaseRegistrationToken:` with the update `fcmToken` as argument.

For example:

```smalltalk
- (void)messaging:(FIRMessaging *)messaging didReceiveRegistrationToken:(NSString *)fcmToken {
    [Optimove.sharedInstance optimoveWithDidReceiveFirebaseRegistrationToken:fcmToken];
}
```

### 5. Important Installation and Usage Notes

The SDK initialization process occurs asynchronously, off the `Main Thread`.

Before calling the Public API methods, make sure that the SDK has finished initialization by calling the `registerSuccessStateDelegate:` method with an instance of `OptimoveSuccessStateDelegate`.


When the SDK has finished its initialization process, the callback `optimove:didBecomeActiveWithMissingPermissions:` is executed with any missing permissions statuses that the SDK would require to operate optimally. 

### 6. Tracking Visitor and Customer activity
 
You will also need to include the following steps to complete the basic setup:

 - Tracking User Activities and Events
 - [Stitching App Visitors to Registered Customer IDs](https://github.com/optimove-tech/A/blob/master/i/V1.2/swift/README.md#stitching-app-visitors-to-registered-customer-ids)
<br>


# <a id="Advanced Setup"></a>Advanced Setup
Use the Advanced Setup (optional) in order to track visitor and customer customized actions and events.
As described in [Tracking Custom Events](https://github.com/optimove-tech/SDK-Custom-Events-for-Your-Vertical), this step requires collaboration between you and Optimove’s Product Integration Team. Please contact your Optimove Customer Success Manager (CSM) or Optimove point of contact to schedule a meeting with the Product Integration team.

>**Note**: You can deploy the basic setup, followed by adding the advanced setup at a later stage. The Basic Setup is a pre-requisite.

<br>
  
# <a id="Track"></a>Track

## <a id="Stitching Visitors to Users"></a>Stitching App Visitors to Registered Customer IDs

Once the user has downloaded the application and the _Optimove SDK_ run for the first time, the user is considered a _Visitor_, i.e. unidentified user<br>

Once the user has authenticated and become identified by a known `PublicCustomerId`, then the user is considered a _Customer_.<br>

As soon as this happens for each individual user, call the following method with the newly acquired  `CustomerId`:<br>

```smalltalk
 [Optimove.sharedInstance setWithUserID:]
```

>**Notes:** 
>- The `CustomerId` is usually provided by the server application that manages customers, and is the **same** ID provided to Optimove during the daily customer data transfer. 
 >- You may call the ` Optimove.sharedInstance setWithUserID:` method at any time, regardless if the initialization success callback was received
> - If you will be sending encrypted userId, please follow the steps in [Reporting encrypted CustomerIDs](https://github.com/optimove-tech/Reporting-Encrypted-CustomerID)
 
<br>

## <a id="Tracking a Screen Visit"></a>Tracking Screen Visits

To track which screens the user has visited in your app, call the following method:<br>

```smalltalk
[Optimove.sharedInstance reportScreenVisitWithViewControllersIdentifiers:url:category:]
```

The `viewControllersIdentifiers` argument should include an array that represents the path of `ViewControllers` to the current screen.<br>
To support more complex view hierarchies, you may also specify a screen URL in the second parameter and give the page a category.<br>

For example:
```smalltalk
 -(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSURL* url = [[NSURL alloc] initWithString:@"http://my.bundle.id/main/cart/pre_checkout"];
    [Optimove.sharedInstance reportScreenVisitWithViewControllersIdentifiers:@[@"main",@"cart"] url:url category:@"Shoes"];
}
```
>Note: The `reportScreenVisitWithViewControllersIdentifiers` method should only be called after the initialization success callback was received.

<br>

## <a id="Tracking Custom Events"></a>Tracking Custom Events  

Optimove clients may use the Optimove Mobile SDK to track specific customer actions and other custom events to Optimove (beyond OOTB events such visits). This data is used for tracking visitor and customer behavior, targeting campaigns to specific visitor and/or customer segments and triggering campaigns based on particular visitor and/or customer actions/events.  
  
To see examples of Custom Events, please visit [Defining the Set of Custom Tracking Events](https://github.com/optimove-tech/SDK-Custom-Events-for-Your-Vertical) that you will report for more information.

>**Note**: While you can always add/change the custom events and parameters at a later date (by speaking with the Optimove Product Integration Team), only the particular custom events that you and the Optimove Product Integration Team have already defined together will be supported by your Optimove site.

### How to Track a Custom Event from within your iOS app

Once you and the Optimove Product Integration Team have together defined the custom events supported by your app, the Product Integration Team will implement your particular functions within your Optimove site, while you will be responsible for implementing the `OptimoveEvent` protocol of the individual events within your app using the appropriate function calls.<br>

The protocol defines 2 properties:
1.	`(NSString*) name` – Declares the custom event’s name
2.	`(NSDictionary*) parameters:` – Defines the custom event's parameters.

Custom Event example:
```smalltalk
@import OptimoveSDK;

@interface MyCustomEvent : NSObject <OptimoveEvent>

@end
@implementation MyCustomEvent


@synthesize name;

@synthesize parameters;

- (instancetype) initWithName:(NSString*) name andParameters:(NSDictionary*) parameters {
    
    if ((self = [super init])) {
        name = name;
        parameters = parameters;
    }
    return self;
}

@end

```

Then send that event through the `reportEvent:` method of the `Optimove` singleton.
  
```smalltalk
NSDictionary* params = @{@"first_param" : @"1"};
    MyCustomEvent* myEvent = [[MyCustomEvent alloc]initWithName:@"event_name" andParameters:params];
    [Optimove.sharedInstance reportEvent:myEvent];
```
<br>

>**Notes**:
>- The `reportEvent:` method should only be called after the initialization success callback was received.
>- As already mentioned, all [custom events](https://github.com/optimove-tech/SDK-Custom-Events-for-Your-Vertical) must be pre-defined in your Tenant configurations by the Optimove Product Integration Team.
>- Reporting of custom events is only supported if you have the basic Mobile SDK setup implemented.
>- Events use **snake_case** as a naming convention. Separate each word with one underscore character (_) and no spaces. (e.g., Checkout_Completed)


# <a id="Trigger"></a>Trigger

## <a id="trigger-optimail"></a>Executing via Optimail
Ability to execute campaigns using Optimove’s Optimail email service provider (ESP) add-on product. With Optimail you will be able to:
* Send HTML email campaigns
* Set personalized tags (first name, last name, and more)
* These Tags are retrieved from both your daily data transfer, as well as the SDK events you are tracking.
* Preview campaign email before sending
* Send realtime marketing campaigns based on your website SDK activity triggering rules

For more information on how to add Optimail to your account, please contact your CSM or your Optimove point of contact.

## <a id="trigger-api"></a>Executing via Optimove APIs
You can also trigger Optimove realtime campaigns using Optimove’s APIs:
* Register listener to receive realtime campaign notifications, please refer to RegisterEventListener (where eventid = 11)
* To view your realtime API payload, please refer to [Optimove Realtime Execution Channels](https://docs.optimove.com/optimove-realtime-execution-channels/) (see Method 3: Realtime API) 
For more information on how to acquire an API key to use Optimove APIs, please request one from your CSM or your Optimove point of contact.

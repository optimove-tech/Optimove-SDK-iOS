-   [Introduction](#Introduction)
- [Basic Setup](#Basic%20Setup)
- [Advanced Setup](#Advanced%20Setup)
-   [Track](#Track)
	-   [Linking App Visitors to Registered Customer IDs](#Linking%20Visitors%20to%20Users)
	-   [Tracking Screen Visits](#Tracking%20a%20Screen%20Visit)
	-   [Reporting Custom Events](https://docs.optimove.com/optimove-sdk/#Web_Reporting_Events)
-   [Trigger](#Trigger)
 	- [Executing via Optimail](#trigger-optimail)
	- [Executing via Optimove APIs](#trigger-api)
<br>

# <a id="Introduction"></a>Introduction
Marketers use the [Optimove Relationship Marketing Hub](https://www.optimove.com/product) to automate the execution of highly-personalized customer communications. Optimove offers its clients an efficient way to report data from their websites and trigger campaigns accordingly.

This guide will show you how to setup the iOS (Objective-C) SDK in order to:

 - Track visitor and customer actions and events
 - Trigger Realtime campaigns

<br>

# <a id="Basic Setup"></a>Basic Setup


## **Request a Mobile SDK from Optimove**

Before implementing the Optimove Track & Trigger to report visitor / customer activities or perform other functions ([OptiPush](https://github.com/optimove-tech/A/blob/master/O/O.md)), you will need to contact your Optimove Customer Success Manager (CSM) or Optimove point of contact. 
To get started, please follow the below instructions: .

### 1. Pre-Requisites:<br>
 1. You have a paid development account for your iOS app, and valid certificates for remote notifications or APN Auth key.
 2. The app's `Deployment Target` is **at least iOS 10.0** 
 3. In order to work with the Optimove SDK for you iOS native app, you also need to download some modules from CocoaPods. </br>
In your **Podfile**, add the following:
 ````objective-c
    pod 'Firebase', '~> 4.11.0' 
    pod 'FirebaseMessaging',  '~> 2.1.1' 
    pod 'FirebaseDynamicLinks',  '~> 2.3.2' 
    pod 'XCGLogger',  '~> 6.0.2' 
    pod 'OptimovePiwikTracker'
````

**Important**: For any Header file that uses the Optimove SDK, add an import with your module name followed by '-Swift.h', such as
````objective-c
#import "HelloWorld-Swift.h" 
````

4. If Your App Already Uses **Firebase**
	The Optimove iOS SDK is dependent upon the Firebase iOS SDK. If your app already uses Firebase SDK or has a dependency with Firebase SDK, a build conflict or runtime exception may occur, due to backward compatibility issues. Therefore, it is highly recommended to match the application’s Firebase SDK version to Optimove’s Firebase SDK:

| Optimove SDK Version | Firebase Core Version | Firebase Messaging Version | FirebaseDynamicLinks |
|----------------------|-----------------------|----------------------------|----------------------|
| 1.0.5.1              | 4.11.0                 | 2.1.1                      | 2.3.2                |
<br>

### 2. Provide your iOS app details:
Send the following information to your CSM or Optimove POC with your request for your Mobile SDK configuration details in order to incorporate into your iOS app :<br>
1.	***Auth key*** (with its key id) P8 format
2.	***Bundle ID*** (If you are using multiple apps for development/testing purposes, please provide a list of all bundle IDs being used for all environments.)
3.	***Team ID*** (from apple developer dashboard)
4.	***App Store ID*** (from itunesconnect) 
<br>

### 3. Retrieve *tenant_information_suite* details:
After providing the info above, you will receive a *tenant_information_suite* from the Optimove Product Integration Team that contains:<br>
1.	***End-point URL*** – The URL where the tenant configurations reside
2.	***Unique Optimove token*** – The actual token, unique per tenant
3.	***Configuration name*** – The version of the desired configuration

For a demo application containing the iOS SDK, please use our [iOS GitHub repository](https://github.com/optimove-tech/iOS-SDK-Integration-Guide/tree/master/DemoApplication/ObjcDemoApp).

<br>

## **Setting Up the iOS SDK**

### 1. Install the SDK
Optimove SDK for iOS is provided as a group of files within a folder named, 'OptimoveSDK'. This folder can be found in this [GitHub repository](https://github.com/optimove-tech/iOS-SDK-Integration-Guide/tree/master/OptimoveSDK). To install the SDK, drag this folder into your project. If not all files inside the folder are members of the target application, add them.

### 2. Run the SDK
In your `AppDelegate` class, inside the application 
````objective-c
application (_: didFinishLaunchingWithOptions:)
```` 
method, create a new `OptimoveTenantInfo` object. This object should contain:

1. The end-point URL
2.	Unique Optimove token
3.	The configuration version provided by the Optimove Integration Team
4.	Indication for existing Firebase module inside your application

Use this object as an argument for the SDK function,

```objective-c
\[Optimove.sharedInstance configureWithInfo:info]; 
```     

This call initializes the `OptimoveSDK` singleton. For example:

       
````objective-c
- (BOOL)application:(UIApplication \*)application
didFinishLaunchingWithOptions:(NSDictionary \*)launchOptions {

// Override point for customization after application launch.

OptimoveTenantInfo \*info = \[\[OptimoveTenantInfo alloc\]
initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com"
token:@"demo\_apps" version:@"1.0.0" hasFirebase:NO\];

\[Optimove.sharedInstance configureWithInfo:info\];
````

>**Note**: The initialization must be called **as soon as possible**, unless you have your own Firebase SDK. In this case, start the initialization right after calling `FirApp configure`.
<br>

### 3. Important Installation and Usage Notes <br>

#### State Registration

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
<br>
 ### 4. Reporting Visitor and Customer activity

You will also need to include the following steps to complete the basic setup:

 - Reporting User Activities and Events
 - [Linking App Visitors to Registered Customer IDs](Linking%20Visitors%20to%20Users)
<br>

# <a id="Advanced Setup"></a>Advanced Setup

Use the Advanced Setup (optional) in order to track visitor and customer customized actions and events.
As described in [Reporting Custom Events](https://github.com/optimove-tech/SDK-Custom-Events-for-Your-Vertical), this step requires collaboration between you and Optimove’s Product Integration Team. Please contact your Optimove Customer Success Manager (CSM) or Optimove point of contact to schedule a meeting with the Product Integration team.

>**Note**: You can deploy the basic setup, followed by adding the advanced setup at a later stage. The Basic Setup is a pre-requisite.

<br>

# <a id="Track"></a>Track

## <a id="Linking Visitors to Users"></a>Linking App Visitors to Registered Customer IDs

Once the user has downloaded the application and the *OptimoveSDK* for iOS has run for the first time, the user is considered a *visitor*, i.e., an unidentified person.

Once the user authenticates and becomes identified by a known `PublicCustomerId`, then the user is considered a *customer*. As soon as this happens for each individual user, pass the `CustomerId` to the `Optimove` singleton like this:

```objective-c
\[Optimove.sharedInstance setWithUserID:@"John Doe"\];
```
       
>**Notes:** 
>
 >- The `CustomerId` is usually provided by the server application that manages customers, and is the same ID provided to Optimove during the daily customer data transfer. 
 >- Due to its high importance, `set (userId:)` may be called at any time, regardless of the SDK’s state
> - If you will be sending encrypted userId, please follow the steps in [Reporting encrypted CustomerIDs](https://github.com/optimove-tech/Reporting-Encrypted-CustomerID)
 
<br>

## <a id="Tracking a Screen Visit"></a>Tracking Screen Visits

To track which screens the user has visited in your app, send a *setScreenEvent* message to the shared Optimove instance:

  ````objective-c
[Optimove.sharedInstance
setScreenEventWithViewControllersIdetifiers:@\[@"vc1",@"vc2"\]
url:nil\];
````

The `viewControllersIdentifiers` argument should include an array that represents the path to the current screen. To support more complex view hierarchies, you may also specify a screen URL in the second parameter.

<br>

## Reporting Custom Events

Optimove clients may use the Optimove Mobile SDK to track specific customer actions and other custom events to Optimove (beyond OOTB events such visits). This data is used for tracking visitor and customer behavior, targeting campaigns to specific visitor and/or customer segments and triggering campaigns based on particular visitor and/or customer actions/events.  
  
To see examples of Custom Events, please visit [Defining the Set of Custom Tracking Events](https://github.com/optimove-tech/SDK-Custom-Events-for-Your-Vertical) that You Will Report for more information.

>**Note**: While you can always add/change the custom events and parameters at a later date (by speaking with the Optimove Product Integration Team), only the particular custom events that you and the Optimove Product Integration Team have already defined together will be supported by your Optimove site.

### How to Report an Custom Event from within your iOS app

Once you and the Optimove Product Integration Team have together defined the custom events supported by your app, the Product Integration Team will implement your particular functions within your Optimove site, while you will be responsible for implementing the `OptimoveEvent` protocol of the individual events within your app using the appropriate function calls.

This `OptimoveEvent` protocol defines two properties:

1.	**name: String** – Declares the custom event’s name
2.	**parameters:NSDictionary  ** – Specifies the custom event’s parameters.

Then, send that event through the `reportEvent(event:)` method of the `Optimove` singleton:

````objective-c
- (IBAction)userPressOnSend:(UIButton *)sender {
    NSString* stringInput = _stringTextField.text;
    NSNumber* numberInput = @([_numberTextField.text intValue]);
    CombinedEvent* event = [[CombinedEvent alloc] initWithStringInput:stringInput andNumberInput:numberInput];
    [Optimove.sharedInstance reportEventWithEvent:event completionHandler:nil];
}
````

>**Notes**:
> - As already mentioned, all custom events must be pre-defined in your Tenant configurations by the Optimove Product Integration Team.
> - Reporting of custom events is only supported if you have the Mobile SDK implemented.
 >- Events use snake_case as a naming convention. Separate each word with one underscore character (_) and no spaces. (e.g., Checkout_Completed)
 >- The usage of the `reportEvent` function depends on your needs. This function may include a completion handler that will be called once the report has finished. The default value for this argument is nil.

<br>

# <a id="Trigger"></a>Trigger

## <a id="trigger-optimail"></a>Executing via Optimail
Ability to execute Realtime campaigns using Optimove’s Optimail email service provider (ESP) add-on product - **Coming Soon**.

For more information on how to add Optimail to your account, please contact your CSM or your Optimove point of contact.

## <a id="trigger-api"></a>Executing via Optimove APIs
Ability to execute Realtime campaigns for mobile native app using Optimove’s APIs -**Coming Soon**

For more information on how to acquire an API key to use Optimove APIs, please request one from your CSM or your Optimove point of contact.

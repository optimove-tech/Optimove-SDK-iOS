Optimove SDK for iOS
====================

Introduction
------------

Marketers use Optimove to automate the execution of highly-personalized
customer relationship marketing plans. The Optimove SDK for iOS offers
Optimove clients an efficient way to integrate their iOS apps with
Optimove for two primary purposes:

-   Reporting user actions and events in realtime (used for customer
    analytics, customer targeting and the delivery of realtime,
    activity-triggered emails and website pop-ups)

-   Enabling Optimove to automatically send hyper-targeted, personalized
    push notification messages to app users (requires purchase of the
    Optipush add-on module)

The primary audience of this document is the technical staff who will
implement the SDK in the company’s apps, while marketing/business
executives may also find it informative.

Prerequisites
-------------

Before you can begin using Optimove SDK for iOS, you will need to
perform the following steps.

1.  Acquire a *tenant\_information\_suite* from the Optimove
    Integration Team. This contains:

    1.  end-point url – The URL where the tenant configurations reside

    2.  token – The actual token, unique per tenant

    3.  config name – The version of the desired configuration

2.  Acquire a paid development account and valid certificates for remote
    notifications or APN Auth key.

3.  Deliver the APN Auth key (preferred) or APN Certificates to your
    Optimove Customer Success Manager (CSM).

4.  *Optional:* Enable push notifications and remote notification
    capabilities in your project.

[![apple_dashboared.png](https://s9.postimg.org/9ln5sfxe7/apple_dashboared.png)](https://postimg.org/image/itfe954gb/)

Installing the SDK
------------------

1.  The SDK is provided as a group of files with a folder
    named, OptimoveSDK.

2.  Drag the folder into your project.

3.  If not all files inside the folder are members of the target
    application add them.

4.  

SDK Setup
---------

In order to work with Optimove SDK, you’ll need to download firebase
relevant modules from cocoapods, Optimove tracking module and a logger
in you Podfile pleaseadd the following lines

pod 'Firebase','~&gt; 4.8.0'

pod 'FirebaseMessaging', '~&gt; 2.0.8'

pod 'FirebaseDynamicLinks', '~&gt; 2.3.1'

pod 'XCGLogger', '~&gt; 6.0.2'

pod 'OptimovePiwikTracker'

On Any Header file that uses the **Optimove SDK,** add an import with
your module name followed by ‘-Swift.h’

In your AppDelegate class, inside the application :
didFinishLaunchingWithOptions: method, create a new OptimoveTenantInfo
object. This object should contain:

1.  Unique Optimove token

2.  The configuration key provided by your CSM

3.  Indication for existing Firebase module inside your application

Use this object as an argument for the SDK function,  
\[Optimove.sharedInstance configureWithInfo:info\];

This call initializes the OptimoveSDK singleton. For example:

- (BOOL)application:(UIApplication \*)application
didFinishLaunchingWithOptions:(NSDictionary \*)launchOptions {

// Override point for customization after application launch.

OptimoveTenantInfo \*info = \[\[OptimoveTenantInfo alloc\]
initWithUrl:@"https://appcontrollerproject-developer.firebaseapp.com"
token:@"demo\_apps" version:@"1.0.0" hasFirebase:NO\];

\[Optimove.sharedInstance configureWithInfo:info\];

The initialization must be called *as soon as possible*, unless the
tenant has its own Firebase SDK. In this case, start the initialization
right after calling \[FIRApp configure\]

### If Your App Already Uses Firebase

The Optimove iOS SDK is dependent upon the Firebase iOS SDK. If your app
already uses Firebase SDK or has a dependency with Firebase SDK, a build
conflict or runtime exception may occur, due to backward compatibility
issues. Therefore, it is highly recommended to match the application’s
Firebase SDK version to Optimove’s Firebase SDK:

| **Optimove SDK Version ** | **Firebase Core Version ** | **Firebase Messaging Version ** | **FirebaseDynamicLinks** |
|---------------------------|----------------------------|---------------------------------|--------------------------|
| 1.0.0                     | 4.8.0                      | 2.0.8                           | 2.3.1                    |

Reporting User Activities and Events 
-------------------------------------

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
daily customer data transfer. Due to its high importance, set (userId:)
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

1.  name: String – Declares the custom event’s name

2.  parameters: \[String:Any\] – Specifies the custom
    event’s parameters.

Then, send that event through the reportEvent(event:) method of the
Optimove singleton:

> override func viewDidAppear(\_ animated: Bool) {
>
> super.viewDidAppear(animated)
>
> \[Optimove.sharedInstance reportEventWithEvent:\[\[MyEvent
> alloc\]init\] completionHandler:nil\];
>
> }

Notes:

-   As already mentioned, all custom events must be pre-defined in your
    Tenant Configurations by the Optimove Integration Team.

-   Reporting of custom events is only supported when you have purchased
    the
    [Optitrack](https://docs.optimove.com/implementing-optitrack-website-visitor-tracking/)
    add-in module is enabled.

-   The usage of the reportEvent function depends on your needs. This
    function may include a completion handler that will be called once
    the report has finished. The default value for this argument is nil.

Delivering Push Notifications
-----------------------------

Optipush is Optimove’s mobile push notification delivery add-in module,
powering all aspects of preparing, delivering and tracking mobile push
notification communications to customers, seamlessly from within
Optimove. Optimove SDK for iOS includes built-in functionality for
receiving push messages, presenting notifications in the app UI and
tracking user responses.

In order for Optipush to be able to deliver push notifications to your
iOS app, Optimove SDK for iOS must receive an APN token from your app.
This is accomplished by the following two steps:

1.  Inside the application’s AppDelegate class
    application:didRegisterForRemoteNotificationsWithDeviceToken:,  
    call \[Optimove.sharedInstance
    applicationWithdidRegisterForRemoteNotificationsWithDeviceToken:\]

2.  In
    application(\_:didReceiveRemoteNotification:fetchCompletionHandler:),
    call \[Optimove.sharedInstance
    handleRemoteNotificationArrived:fetchCompletionHandler\]

For example:

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

### Deep Linking Notifications to a Particular App Screen

Other than UI attributes, an Optipush notification <span
id="_Hlk502568927" class="anchor"></span>may also contain metadata
linking to a specific screen within your app, along with custom
(screen-specific) data.

To support deep linking, enable Associated Domains. To do so: In your
project capabilities, add the deep link domain (provided by Optimove
CSM) with the applinks: prefix and without any https:// prefix.

[![associated_domain.png](https://s9.postimg.org/hqrw4eqm7/associated_domain.png)](https://postimg.org/image/3x3jfcy0r/)

Any ViewController should receive a DeepLink data callback, and should
implement didReceive(deepLink:), thus conforming to the DeepLinkCallback
protocol.

The DeepLinkCallback protocol has one method:

> didReceive(deepLink:)

The deepLinkComponent structure contains two properties:

-   **ScreenName** – for the required ViewController you need to segue
    to

-   **Query** – contains the content that should be included in that
    view controller

For example:

- (void) didReceiveWithDeepLink:(OptimoveDeepLinkComponents \*)deepLink
{

ViewController\* vc = \[\[ViewController alloc\]
initWithNibName:deepLink.screenName bundle:nil\];

\[\[self navigationController\] pushViewController:vc animated:true\]; }

### Testing Push Notification Templates

It is usually desirable to test an Optipush push notification template
on an actual device before sending an Optipush campaign to users.

To enable “test campaigns” on one or more devices, call the
\[Optimove.sharedInstance subscribeToTestMode\]\`method.

To stop receiving “test campaigns,” call \[Optimove.sharedInstance
unSubscribeFromTestMode\].

-(void)viewDidAppear:(BOOL)animated {

\[super viewDidAppear:animated\];

\[Optimove.sharedInstance subscribeToTestMode\];

}

In order to test a push notification template, the marketer can send a
test push notification campaign from within Optimove (using the Optipush
UI). Notifications from such a campaign will only be delivered to
devices running the version of your app in which the above “test
campaigns” method was called.

# Changelog

## 2.10.0

- **add** SPM support.
- **remove** test mode API.
- **remove** firebase dependency.

## 2.9.1

- **hotfix** safety wrap the SDK initialization to prevent from a crash regarding a corrupt file system access.

## 2.9.0

- **fix** carthage firebase dependency for version 6.15.
- **fix** set_user_id issue if it calls before `configure`.

## 2.8.1

- **fix** xcode 10 build.

## 2.8.0

- **improve** an apns environment checking.
- **improve** updating for an actual token.
- **change** enabling debug logging.
- **fix** main-thread sanity warnings.

## 2.7.0

- **added** expose version number
- **changed** access level for notification service operations.

## 2.6.0

- **changed** API communication
- **fixed** error handling
- **fixed** notification payload model (optional title)

## 2.5.1

* **fixed** compatibility with Swift 5.0.3.
* **fixed** `OptimoveCore` explicit version for other Optimove frameworks.

## 2.5.0

* **added** new API `didReceivePushAuthorization(fromUserNotificationCenter: Bool)`.
* **added** support for `UNAuthorizationStatus.provisional`.
* **added** handling Notification authorization changes on an app lifecycle.
* **BREAKING change** `OptimoveEvent` is now available under the `OptimoveCore` framework instead of the `OptimoveSDK`.

> The Optimove SDK is following _semvar_. Exceptionally, this change is not considered a major release.

## 2.4.0

* **introduced** a new API for working with Apple tokens directly.

## 2.3.0

* **removed** `OptimoveStateListener` – use the SDK directly.
* **added** `OptimoveCore` – a framework for share a code-base between the SDK and the NSE.
* **changed** `OptimoveEvent` – moved to the `OptimoveCore` module.

## 2.2.2

* **fixed** – The realtime race condition issue fixed on the mobile-side by introducing a delay between requests.
* **fixed** – Notification Payload's deep link property changed to optional.

* **introduced** – `OPTIMOVE_RELEASE_VERSION` key used a value for unifying apps version.
* **introduced** – Experimentally Carthage support.

## 2.2.1

* **fixed** – The SDK state listeners never called.

## 2.2.0

* **introduced** – `OPTIMOVE_SDK_ENVIRONMENT` key used for choosing a logging endpoint. The default value is `production`.

## 2.1.0

* Updated Firebase versions.
  * FirebaseDynamicLinks, '4.0.0'
  * FirebaseMessaging, '4.0.2'

## 2.0.2

* **deprecated** – `registerUser(email:userId:)` and exposed `registerUser(sdkId:email)`

## 2.0.1

* Internal bug fixes.

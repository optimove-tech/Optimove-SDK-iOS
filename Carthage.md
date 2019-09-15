# Optimove Carthage

This page provides instructions for an Optimove Carthage distribution.

## Cartage installation

[Homebrew](http://brew.sh/) is one way to install Carthage.

```bash
brew update
brew install carthage
```

See the
[Carthage page](https://github.com/Carthage/Carthage#installing-carthage) for
more details and additional installation methods.

## Cartage usage

* Create or update a Cartfile

```
github "optimove-tech/Optimove-SDK-iOS"
```

* Run `carthage update`.
* Choose a target for adding Optimove in an Xcode project.
* Add to "Linked Frameworks and Libraries" by taking new components from `Carthage/Build/iOS`.
* Add `$(OTHER_LDFLAGS) -ObjC` flag to "Other Linker Flags" in "Build Settings".
* Delete [Firebase.framework](https://github.com/firebase/firebase-ios-sdk/issues/911#issuecomment-372455235) from the "Link Binary With Libraries" of the "Build Phase" tab.
* Add the path under “Input Files":

```
$(SRCROOT)/Carthage/Build/iOS/OptimoveCore.framework
```

* Remark that you shouldn't add the Optimove and Firebase frameworks to the Carthage build phase (`copy-frameworks`). The frameworks include static libraries that are linked at build time.

Since Optimove SDK uses a [Firebase](https://github.com/firebase/firebase-ios-sdk) dependency you can verify [installation on Firebase components](https://github.com/firebase/firebase-ios-sdk/blob/master/Carthage.md).

Please [let us know](https://github.com/optimove-tech/iOS-SDK-Integration-Guide/issues) if you have suggestions or questions.

### Description of Changes

(briefly outline the reason for changes, and describe what's been done)

### Breaking Changes

-   None

### Release Checklist

### Prepare:

- [ ] Detail any breaking changes. Breaking changes require a new major version number
- [ ] Check `pod lib lint` passes
- [ ] Update any relevant sections of the repository wiki pages on a branch

### Bump versions in:

- [ ] `OptimoveCore.podspec`
- [ ] `OptimoveNotificationServiceExtension.podspec`
- [ ] `OptimoveSDK.podspec`

- [ ] `OptimoveCore/Sources/Classes/Constants/SDKVersion.swift`

- [ ] `README.md`
- [ ] `CHANGELOG.md`

### Integration tests

*T&T Only*

- [ ] Init SDK with only T&T credentials
- [ ] Associate customer
- [ ] Associate email
- [ ] Track events

*Mobile Only*

- [ ] Init SDK with all credentials
- [ ] Track events
- [ ] Associate customer (verify both backends)
- [ ] Register for push
- [ ] Opt-in for In-App
- [ ] Send test push
- [ ] Send test In-App
- [ ] Receive / trigger deep link handler (In-App/Push)
- [ ] Receive / trigger the content extension, render image and action buttons for push
- [ ] Verify push opened handler

*Deferred Deep Links*

- [ ] With app installed, trigger deep link handler
- [ ] With app uninstalled, follow deep link, install test bundle, verify deep link read from Clipboard, trigger deep link handler

*Combined*

- [ ] Track event for T&T, verify push received
- [ ] Trigger scheduled campaign, verify push received
- [ ] Trigger scheduled campaign, verify In-App received

### Release:

- [ ] Squash and merge to master
- [ ] Delete branch once merged
- [ ] Create tag from master matching chosen version
- [ ] Run `pod trunk push` to publish to CocoaPods

### Post Release:

- [ ] Push wiki pages to master


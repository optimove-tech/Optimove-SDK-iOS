//  Copyright © 2026 Optimove. All rights reserved.

import UIKit
import UserNotifications
import XCTest
@testable import OptimoveSDK

final class FakePushPermissionCenter: PushPermissionCenter {
    var status: UNAuthorizationStatus
    var promptResult: (granted: Bool, error: Error?) = (true, nil)
    private(set) var promptCount = 0

    init(status: UNAuthorizationStatus) {
        self.status = status
    }

    func authorizationStatus(_ completion: @escaping (UNAuthorizationStatus) -> Void) {
        completion(status)
    }

    func requestAuthorization(_ completion: @escaping (Bool, Error?) -> Void) {
        promptCount += 1
        completion(promptResult.granted, promptResult.error)
    }
}

private final class RecordedEvents {
    private(set) var events: [(OptimobileEvent, [String: Any])] = []

    var track: PushEventTracker {
        { [self] event, properties in events.append((event, properties)) }
    }
}

/// AC-7: `k.push.deviceRegistered` reports whether notifications are allowed.
final class PushRegistrationFlagTests: XCTestCase {
    private func registeredFlag(for status: UNAuthorizationStatus) -> Any? {
        let recorded = RecordedEvents()
        Optimobile.pushRegister(Data([0xAB, 0xCD]), deviceType: 1, iosTokenType: 1,
                                center: FakePushPermissionCenter(status: status), track: recorded.track)
        XCTAssertEqual(recorded.events.count, 1)
        XCTAssertEqual(recorded.events.first?.0, .PUSH_DEVICE_REGISTER)
        XCTAssertEqual(recorded.events.first?.1["token"] as? String, "abcd")
        return recorded.events.first?.1["areNotificationsEnabled"]
    }

    func test_ac7_enabledStatuses_reportTrue() {
        var statuses: [UNAuthorizationStatus] = [.authorized, .provisional]
        if #available(iOS 14.0, *) { statuses.append(.ephemeral) }
        for status in statuses {
            XCTAssertEqual(registeredFlag(for: status) as? Bool, true, "status \(status.rawValue)")
        }
    }

    func test_ac7_disabledStatuses_reportFalse() {
        for status: UNAuthorizationStatus in [.denied, .notDetermined] {
            XCTAssertEqual(registeredFlag(for: status) as? Bool, false, "status \(status.rawValue)")
        }
    }
}

/// AC-8: a change in notification permission is reported once, on start and on each return to foreground.
final class NotificationEnablementChangeTests: XCTestCase {
    private let key = OptimobileUserDefaultsKey.NOTIFICATIONS_ENABLED.rawValue

    override func setUp() {
        super.setUp()
        KeyValPersistenceHelper.removeObject(forKey: key)
    }

    override func tearDown() {
        KeyValPersistenceHelper.removeObject(forKey: key)
        super.tearDown()
    }

    private func check(_ status: UNAuthorizationStatus, recorded: RecordedEvents) {
        Optimobile.reportNotificationEnablementIfChanged(center: FakePushPermissionCenter(status: status), track: recorded.track)
    }

    func test_ac8_firstCheckWhenEnabled_sendsEventAndPersists() {
        let recorded = RecordedEvents()
        check(.authorized, recorded: recorded)

        XCTAssertEqual(recorded.events.count, 1)
        XCTAssertEqual(recorded.events.first?.0, .PUSH_NOTIFICATION_ENABLEMENT_CHANGED)
        XCTAssertEqual(recorded.events.first?.1["notificationsEnabled"] as? Bool, true)
        XCTAssertEqual(KeyValPersistenceHelper.object(forKey: key) as? Bool, true)
    }

    func test_ac8_firstCheckWhenDisabled_sendsNothing() {
        let recorded = RecordedEvents()
        check(.denied, recorded: recorded)
        XCTAssertTrue(recorded.events.isEmpty)
    }

    func test_ac8_unchanged_sendsNothing() {
        let recorded = RecordedEvents()
        check(.authorized, recorded: recorded)
        check(.provisional, recorded: recorded)
        XCTAssertEqual(recorded.events.count, 1)
    }

    func test_ac8_changeBackToDisabled_sendsFalseOnce() {
        let recorded = RecordedEvents()
        check(.authorized, recorded: recorded)
        check(.denied, recorded: recorded)
        check(.denied, recorded: recorded)

        XCTAssertEqual(recorded.events.count, 2)
        XCTAssertEqual(recorded.events.last?.1["notificationsEnabled"] as? Bool, false)
        XCTAssertEqual(KeyValPersistenceHelper.object(forKey: key) as? Bool, false)
    }
}

/// AC-8 wiring: the check runs when the SDK starts (it may be configured after the first foreground) and on every foreground.
final class NotificationEnablementWiringTests: XCTestCase {
    private func makeHelper(onCheck: @escaping () -> Void) -> SessionHelper {
        let helper = SessionHelper(sessionIdleTimeout: 1, trackForeground: {}, checkNotificationEnablement: onCheck)
        helper.initialize()
        return helper
    }

    func test_ac8_sdkInit_runsTheCheck() {
        var checks = 0
        _ = makeHelper { checks += 1 }
        XCTAssertEqual(checks, 1)
    }

    func test_ac8_eachForeground_runsTheCheck() {
        var checks = 0
        let helper = makeHelper { checks += 1 }
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(checks, 3, "init plus two foregrounds")
        withExtendedLifetime(helper) {}
    }
}

/// AC-9: `pushUnregister()` is still a full opt-out.
final class PushUnregisterTests: XCTestCase {
    func test_ac9_pushUnregister_sendsDeviceUnsubscribed() {
        let recorded = RecordedEvents()
        Optimobile.pushUnregister(track: recorded.track)

        XCTAssertEqual(recorded.events.count, 1)
        XCTAssertEqual(recorded.events.first?.0, .DEVICE_UNSUBSCRIBED)
    }
}

/// AC-6: the SDK registers for remote notifications whatever the notification permission is.
final class PushRegistrationAlwaysTests: XCTestCase {
    private func runRequestToken(
        center: FakePushPermissionCenter,
        inBackground: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> [String] {
        var events: [String] = []
        let registered = expectation(description: "registerForRemoteNotifications called")

        Optimobile.requestToken(
            center: center,
            isInBackground: { inBackground },
            registerForRemoteNotifications: {
                events.append("register")
                registered.fulfill()
            },
            { status, _ in events.append("status:\(status.rawValue)") }
        )

        let result = XCTWaiter().wait(for: [registered], timeout: 1)
        XCTAssertEqual(result, .completed, "registerForRemoteNotifications was not called", file: file, line: line)
        return events
    }

    // AC-6
    func test_ac6_authorized_registers() {
        let events = runRequestToken(center: FakePushPermissionCenter(status: .authorized))
        XCTAssertEqual(events, ["status:\(UNAuthorizationStatus.authorized.rawValue)", "register"])
    }

    // AC-6
    func test_ac6_denied_registersAndReportsDenied() {
        let events = runRequestToken(center: FakePushPermissionCenter(status: .denied))
        XCTAssertEqual(events, ["status:\(UNAuthorizationStatus.denied.rawValue)", "register"])
    }

    // AC-6
    func test_ac6_promptAccepted_registers() {
        let center = FakePushPermissionCenter(status: .notDetermined)
        let events = runRequestToken(center: center)
        XCTAssertEqual(center.promptCount, 1)
        XCTAssertEqual(events, ["status:\(UNAuthorizationStatus.authorized.rawValue)", "register"])
    }

    // AC-6
    func test_ac6_promptDeclined_registersAndReportsDenied() {
        let center = FakePushPermissionCenter(status: .notDetermined)
        center.promptResult = (false, nil)
        let events = runRequestToken(center: center)
        XCTAssertEqual(center.promptCount, 1)
        XCTAssertEqual(events, ["status:\(UNAuthorizationStatus.denied.rawValue)", "register"])
    }

    // AC-6
    func test_ac6_promptFails_registersAndReportsNotDetermined() {
        let center = FakePushPermissionCenter(status: .notDetermined)
        center.promptResult = (false, NSError(domain: "test", code: 1))
        let events = runRequestToken(center: center)
        XCTAssertEqual(events, ["status:\(UNAuthorizationStatus.notDetermined.rawValue)", "register"])
    }

    // AC-6
    func test_ac6_appInBackground_doesNotPromptButRegisters() {
        let center = FakePushPermissionCenter(status: .notDetermined)
        let events = runRequestToken(center: center, inBackground: true)
        XCTAssertEqual(center.promptCount, 0)
        XCTAssertEqual(events, ["status:\(UNAuthorizationStatus.notDetermined.rawValue)", "register"])
    }
}

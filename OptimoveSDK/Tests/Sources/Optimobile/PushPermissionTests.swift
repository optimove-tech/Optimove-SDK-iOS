//  Copyright © 2026 Optimove. All rights reserved.

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

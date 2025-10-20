import XCTest
@testable import OptimoveSDK

final class SessionHelperTests: XCTestCase {

    func test_sessionDidEnd_returnsImmediately_underSlowNetwork() {
        let delay: TimeInterval = 2.5
        let delayedMock: (Date, @escaping SyncCompletedBlock) -> Void = { _, done in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                done(nil)
            }
        }

        let helper = SessionHelper(sessionIdleTimeout: 1, trackBackground: delayedMock)
        helper.setBecameInactiveAtForTest(Date())

        let start = CFAbsoluteTimeGetCurrent()
        helper.sessionDidEnd()
        let elapsedMs = (CFAbsoluteTimeGetCurrent() - start) * 1000

        XCTAssertLessThan(elapsedMs, 100, "sessionDidEnd should not block the caller")
    }

    func test_sessionDidEnd_completionFires_async() {
        let completionExpectation = expectation(description: "onSyncComplete fired")
        let delay: TimeInterval = 2.0
        let delayedMock: (Date, @escaping SyncCompletedBlock) -> Void = { _, done in
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                done(nil)
                completionExpectation.fulfill()
            }
        }

        let helper = SessionHelper(sessionIdleTimeout: 1, trackBackground: delayedMock)
        helper.setBecameInactiveAtForTest(Date())

        helper.sessionDidEnd()

        waitForExpectations(timeout: delay + 1.0)
    }
}



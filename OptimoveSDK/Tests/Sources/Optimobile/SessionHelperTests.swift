import XCTest
@testable import OptimoveSDK

final class SessionHelperTests: XCTestCase {

    private let timeoutInSeconds = 10.0

    // Both tests previously encoded "does not block" as wall-clock measurements:
    // an elapsed-time assertion of under 100ms, and a 2 second sleep inside a 3
    // second timeout. Neither survives a loaded CI runner, where scheduling delay
    // alone can exceed the margin even though the behaviour is correct. They now
    // assert ordering instead, so the timeouts are only a backstop against a real
    // hang rather than the thing being measured.

    func test_sessionDidEnd_doesNotWaitForTrackingToComplete() {
        // Held until the test releases it, so the tracking completion cannot run
        // before sessionDidEnd has returned.
        let releaseTracking = DispatchSemaphore(value: 0)
        let trackingInvoked = expectation(description: "trackBackground was invoked")
        let sessionDidEndReturned = expectation(description: "sessionDidEnd returned")

        let blockingMock: (Date, @escaping SyncCompletedBlock) -> Void = { _, done in
            trackingInvoked.fulfill()
            DispatchQueue.global().async {
                releaseTracking.wait()
                done(nil)
            }
        }

        let helper = SessionHelper(sessionIdleTimeout: 1, trackBackground: blockingMock)
        helper.setBecameInactiveAtForTest(Date())

        DispatchQueue.global().async {
            helper.sessionDidEnd()
            sessionDidEndReturned.fulfill()
        }

        // sessionDidEnd has to return while tracking is still outstanding. If it
        // waited for done(nil), it would block on releaseTracking, which is only
        // signalled below, and this wait would time out.
        wait(for: [trackingInvoked, sessionDidEndReturned], timeout: timeoutInSeconds)

        releaseTracking.signal()
    }

    // The mock is what defers here, so this only covers that sessionDidEnd routes
    // through trackBackground and its completion runs. Asynchrony of the SDK's own
    // call is covered by the test above.
    func test_sessionDidEnd_invokesTrackingCompletion() {
        let completionFired = expectation(description: "onSyncComplete fired")

        let asyncMock: (Date, @escaping SyncCompletedBlock) -> Void = { _, done in
            DispatchQueue.global().async {
                done(nil)
                completionFired.fulfill()
            }
        }

        let helper = SessionHelper(sessionIdleTimeout: 1, trackBackground: asyncMock)
        helper.setBecameInactiveAtForTest(Date())

        helper.sessionDidEnd()

        wait(for: [completionFired], timeout: timeoutInSeconds)
    }
}

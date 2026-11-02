import XCTest
@testable import OptimoveSDK

final class OverlayLifecycleNotifierTests: XCTestCase {

    private func makeMessage(id: Int64 = 1) -> OverlayMessagingMessage {
        OverlayMessagingMessage(id: id, content: [:], data: nil, type: .immediate)
    }

    private func makeNotifier(_ spy: SpyListener, logError: @escaping (String) -> Void = { _ in }) -> OverlayLifecycleNotifier {
        let notifier = OverlayLifecycleNotifier(logError: logError)
        notifier.setListener(spy)
        return notifier
    }

    // MARK: - onShown

    func testShownFiresOncePerMessage() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let message = makeMessage()

        notifier.messagePresented(message)
        notifier.messagePresented(message) // e.g. show() after hide()

        XCTAssertEqual(spy.log, ["shown:1"])
    }

    // MARK: - onClosed reasons

    func testUserCloseWithoutActionIsDismissed() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let message = makeMessage()

        notifier.messagePresented(message)
        notifier.messageClosed(message, failed: false)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:dismissed"])
    }

    func testCloseAfterLinkActionIsActioned() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let message = makeMessage()

        notifier.messagePresented(message)
        notifier.linkActionDispatched(message)
        notifier.messageClosed(message, failed: false)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:actioned"])
    }

    func testPresentationFailureIsError() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let message = makeMessage()

        notifier.messagePresented(message)
        notifier.linkActionDispatched(message)
        notifier.messageClosed(message, failed: true)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:error"])
    }

    func testActionedDoesNotCarryOverToNextMessage() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let first = makeMessage(id: 1)
        let second = makeMessage(id: 2)

        notifier.messagePresented(first)
        notifier.linkActionDispatched(first)
        notifier.messageClosed(first, failed: false)
        notifier.messagePresented(second)
        notifier.messageClosed(second, failed: false)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:actioned", "shown:2", "closed:2:dismissed"])
    }

    // MARK: - Exactly once

    func testClosedFiresAtMostOncePerShownMessage() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let message = makeMessage()

        notifier.messagePresented(message)
        notifier.messageClosed(message, failed: true)
        notifier.messageClosed(message, failed: true)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:error"])
    }

    func testCloseForMessageNeverShownIsIgnored() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)

        notifier.messageClosed(makeMessage(), failed: false)

        XCTAssertEqual(spy.log, [])
    }

    func testMessageCanBeShownAgainAfterClose() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        let message = makeMessage()

        notifier.messagePresented(message)
        notifier.messageClosed(message, failed: false)
        notifier.messagePresented(message)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:dismissed", "shown:1"])
    }

    // MARK: - Registration

    func testNoListenerIsSafeAndClearingStopsCallbacks() {
        let spy = SpyListener()
        let notifier = makeNotifier(spy)
        notifier.setListener(nil)

        notifier.messagePresented(makeMessage())
        notifier.messageClosed(makeMessage(), failed: false)

        XCTAssertEqual(spy.log, [])
    }

    func testDefaultImplementationsAreNoOps() {
        struct EmptyListener: OverlayLifecycleListener {}
        let notifier = OverlayLifecycleNotifier(logError: { XCTFail($0) })
        notifier.setListener(EmptyListener())

        notifier.messagePresented(makeMessage())
        notifier.messageClosed(makeMessage(), failed: false)
    }

    // MARK: - Fail-closed

    func testThrowingListenerIsLoggedAndStateStillAdvances() {
        struct TestError: Error {}
        var logged: [String] = []
        let spy = SpyListener(throwing: TestError())
        let notifier = makeNotifier(spy, logError: { logged.append($0) })
        let message = makeMessage()

        XCTAssertNoThrow(notifier.messagePresented(message))
        XCTAssertNoThrow(notifier.messageClosed(message, failed: false))
        notifier.messageClosed(message, failed: false)

        XCTAssertEqual(spy.log, ["shown:1", "closed:1:dismissed"])
        XCTAssertEqual(logged.count, 2)
    }

    // MARK: - Reason

    func testUnknownReasonRoundTrips() {
        let reason = OverlayCloseReason(rawValue: "future")
        XCTAssertEqual(reason.rawValue, "future")
        XCTAssertNotEqual(reason, .dismissed)
    }
}

// MARK: - Test helpers

private final class SpyListener: OverlayLifecycleListener {
    private(set) var log: [String] = []
    private let error: Error?

    init(throwing error: Error? = nil) {
        self.error = error
    }

    func onShown(message: OverlayMessagingMessage) throws {
        log.append("shown:\(message.id)")
        if let error = error { throw error }
    }

    func onClosed(message: OverlayMessagingMessage, info: OverlayClosedInfo) throws {
        log.append("closed:\(message.id):\(info.reason.rawValue)")
        if let error = error { throw error }
    }
}

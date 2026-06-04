import XCTest
@testable import OptimoveSDK

final class OverlayActionDispatcherTests: XCTestCase {

    private func makeMessage() -> OverlayMessagingMessage {
        OverlayMessagingMessage(id: 1, content: [:], data: nil, type: .immediate)
    }

    // MARK: - No handler

    func testDispatchReturnsFalseWhenNoHandlerRegistered() {
        let dispatcher = OverlayActionDispatcher()
        let consumed = dispatcher.dispatch(.linkAction, message: makeMessage(), data: ["url": "https://example.com"])
        XCTAssertFalse(consumed)
    }

    // MARK: - Registered handler

    func testDispatchInvokesHandlerWithMessageAndDataAndReturnsTrue() {
        var receivedMessage: OverlayMessagingMessage?
        var receivedData: [String: Any]?
        let dispatcher = OverlayActionDispatcher()
        let message = makeMessage()
        let data: [String: Any] = ["url": "https://example.com"]

        dispatcher.setHandler(.linkAction) { msg, d in
            receivedMessage = msg
            receivedData = d
        }

        let consumed = dispatcher.dispatch(.linkAction, message: message, data: data)

        XCTAssertTrue(consumed)
        XCTAssertEqual(receivedMessage?.id, message.id)
        XCTAssertEqual(receivedData?["url"] as? String, "https://example.com")
    }

    // MARK: - Fail-closed

    func testThrowingHandlerStillReturnsTrueAndLogsError() {
        struct TestError: Error {}
        var loggedMessage: String?
        let dispatcher = OverlayActionDispatcher(logError: { loggedMessage = $0 })

        dispatcher.setHandler(.linkAction) { _, _ in throw TestError() }

        let consumed = dispatcher.dispatch(.linkAction, message: makeMessage(), data: ["url": "x"])

        XCTAssertTrue(consumed)
        XCTAssertNotNil(loggedMessage)
    }

    // MARK: - Unregistered type falls through

    func testDispatchReturnsFalseForTypeWithNoHandler() {
        let dispatcher = OverlayActionDispatcher()
        let consumed = dispatcher.dispatch(.linkAction, message: makeMessage(), data: ["url": "x"])
        XCTAssertFalse(consumed)
    }

    func testHandlerForRegisteredTypeDoesNotAffectUnregisteredDispatch() {
        var handlerCalled = false
        let dispatcherA = OverlayActionDispatcher()
        dispatcherA.setHandler(.linkAction) { _, _ in handlerCalled = true }

        let dispatcherB = OverlayActionDispatcher()
        let consumed = dispatcherB.dispatch(.linkAction, message: makeMessage(), data: [:])

        XCTAssertFalse(consumed)
        XCTAssertFalse(handlerCalled)
    }

    // MARK: - Clear handler

    func testClearedHandlerFallsBackToDefault() {
        var handlerCalled = false
        let dispatcher = OverlayActionDispatcher()
        dispatcher.setHandler(.linkAction) { _, _ in handlerCalled = true }
        dispatcher.setHandler(.linkAction, nil)

        let consumed = dispatcher.dispatch(.linkAction, message: makeMessage(), data: ["url": "x"])

        XCTAssertFalse(consumed)
        XCTAssertFalse(handlerCalled)
    }

    // MARK: - Re-register replaces

    func testReRegisteringReplacesHandler() {
        var firstCalled = false
        var secondCalled = false
        let dispatcher = OverlayActionDispatcher()
        dispatcher.setHandler(.linkAction) { _, _ in firstCalled = true }
        dispatcher.setHandler(.linkAction) { _, _ in secondCalled = true }

        dispatcher.dispatch(.linkAction, message: makeMessage(), data: ["url": "x"])

        XCTAssertFalse(firstCalled)
        XCTAssertTrue(secondCalled)
    }
}

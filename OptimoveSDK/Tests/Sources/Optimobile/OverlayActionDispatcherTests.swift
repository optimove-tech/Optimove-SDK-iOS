import XCTest
@testable import OptimoveSDK

final class OverlayActionDispatcherTests: XCTestCase {

    private func makeMessage() -> OverlayMessagingMessage {
        OverlayMessagingMessage(id: 1, content: [:], data: nil, type: .immediate)
    }

    private func makeLinkAction(url: String = "https://example.com") -> OverlayAction {
        .linkAction(LinkActionPayload(url: url))
    }

    // MARK: - SDK default

    func testUsesSDKDefaultWhenNoOverrideIsRegistered() {
        var defaultCalled = false
        let defaults = SpyHandler(onLinkAction: { _, _ in defaultCalled = true })
        let dispatcher = OverlayActionDispatcher(defaults: defaults)

        dispatcher.dispatch(makeLinkAction(), message: makeMessage())

        XCTAssertTrue(defaultCalled)
    }

    // MARK: - Client override

    func testCallsOverrideInsteadOfDefaultForOverriddenAction() {
        var defaultCalled = false
        var overrideCalled = false
        let defaults = SpyHandler(onLinkAction: { _, _ in defaultCalled = true })
        let override = SpyHandler(onLinkAction: { _, _ in overrideCalled = true })
        let dispatcher = OverlayActionDispatcher(defaults: defaults)

        dispatcher.setOverrides(override)
        dispatcher.dispatch(makeLinkAction(), message: makeMessage())

        XCTAssertTrue(overrideCalled)
        XCTAssertFalse(defaultCalled)
    }

    func testOverrideReceivesCorrectMessageAndData() {
        var receivedMessage: OverlayMessagingMessage?
        var receivedData: LinkActionPayload?
        let dispatcher = OverlayActionDispatcher(defaults: SpyHandler())
        let override = SpyHandler(onLinkAction: { msg, payload in
            receivedMessage = msg
            receivedData = payload
        })
        let message = makeMessage()

        dispatcher.setOverrides(override)
        dispatcher.dispatch(makeLinkAction(url: "https://example.com/path"), message: message)

        XCTAssertEqual(receivedMessage?.id, message.id)
        XCTAssertEqual(receivedData?.url, "https://example.com/path")
    }

    // MARK: - Clear overrides restores default

    func testClearingOverridesRestoresSDKDefault() {
        var defaultCalled = false
        var overrideCalled = false
        let defaults = SpyHandler(onLinkAction: { _, _ in defaultCalled = true })
        let override = SpyHandler(onLinkAction: { _, _ in overrideCalled = true })
        let dispatcher = OverlayActionDispatcher(defaults: defaults)

        dispatcher.setOverrides(override)
        dispatcher.setOverrides(nil)
        dispatcher.dispatch(makeLinkAction(), message: makeMessage())

        XCTAssertTrue(defaultCalled)
        XCTAssertFalse(overrideCalled)
    }

    // MARK: - Fail-closed

    func testThrowingHandlerIsLoggedAndDoesNotPropagate() {
        struct TestError: Error {}
        var loggedMessage: String?
        let throwing = SpyHandler(onLinkAction: { _, _ in throw TestError() })
        let dispatcher = OverlayActionDispatcher(defaults: throwing, logError: { loggedMessage = $0 })

        XCTAssertNoThrow(dispatcher.dispatch(makeLinkAction(), message: makeMessage()))
        XCTAssertNotNil(loggedMessage)
    }

    func testThrowingOverrideIsLoggedAndDoesNotPropagate() {
        struct TestError: Error {}
        var loggedMessage: String?
        let throwing = SpyHandler(onLinkAction: { _, _ in throw TestError() })
        let dispatcher = OverlayActionDispatcher(defaults: SpyHandler(), logError: { loggedMessage = $0 })

        dispatcher.setOverrides(throwing)

        XCTAssertNoThrow(dispatcher.dispatch(makeLinkAction(), message: makeMessage()))
        XCTAssertNotNil(loggedMessage)
    }
}

// MARK: - Test helpers

private final class SpyHandler: OverlayActionHandler {
    private let onLinkAction: (OverlayMessagingMessage, LinkActionPayload) throws -> Void

    init(onLinkAction: @escaping (OverlayMessagingMessage, LinkActionPayload) throws -> Void = { _, _ in }) {
        self.onLinkAction = onLinkAction
    }

    func linkAction(message: OverlayMessagingMessage, payload: LinkActionPayload) throws {
        try onLinkAction(message, payload)
    }
}

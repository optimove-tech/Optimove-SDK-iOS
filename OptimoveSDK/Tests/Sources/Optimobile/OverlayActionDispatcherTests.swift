import XCTest
@testable import OptimoveSDK

final class OverlayActionDispatcherTests: XCTestCase {

    private func makeMessage() -> OverlayMessagingMessage {
        OverlayMessagingMessage(
            id: 1,
            content: ["title": "Test"],
            data: ["campaign": "A"],
            type: .immediate
        )
    }

    private func makeLinkData(url: String = "https://example.com/path") -> NSDictionary {
        ["url": url]
    }

    // MARK: - Default behaviour

    func testButtonLinkWithoutHandlerOpensURL() {
        var openedURL: URL?
        let dispatcher = OverlayActionDispatcher(
            handlerForType: { _ in nil },
            openURL: { openedURL = $0 },
            logError: { _ in }
        )

        dispatcher.performButtonLink(message: makeMessage(), data: makeLinkData())

        XCTAssertEqual(openedURL?.absoluteString, "https://example.com/path")
    }

    func testButtonLinkWithoutHandlerDoesNotOpenInvalidURL() {
        var openCalled = false
        let dispatcher = OverlayActionDispatcher(
            handlerForType: { _ in nil },
            openURL: { _ in openCalled = true },
            logError: { _ in }
        )

        dispatcher.performButtonLink(message: makeMessage(), data: ["url": ""])

        XCTAssertFalse(openCalled)
    }

    func testButtonLinkWithoutURLInDataDoesNothing() {
        var openCalled = false
        var handleCallCount = 0
        let dispatcher = OverlayActionDispatcher(
            handlerForType: { _ in { _, _ in handleCallCount += 1 } },
            openURL: { _ in openCalled = true },
            logError: { _ in }
        )

        dispatcher.performButtonLink(message: makeMessage(), data: [:])

        XCTAssertEqual(handleCallCount, 0)
        XCTAssertFalse(openCalled)
    }

    // MARK: - Custom handler

    func testButtonLinkWithHandlerReceivesMessageAndData() {
        var handleCallCount = 0
        var lastMessage: OverlayMessagingMessage?
        var lastData: [String: Any]?
        var openCalled = false
        let message = makeMessage()
        let data = makeLinkData(url: "myapp://screen")

        let dispatcher = OverlayActionDispatcher(
            handlerForType: { type in
                guard type == .buttonLink else { return nil }
                return { msg, payload in
                    handleCallCount += 1
                    lastMessage = msg
                    lastData = payload
                }
            },
            openURL: { _ in openCalled = true },
            logError: { _ in }
        )

        dispatcher.performButtonLink(message: message, data: data)

        XCTAssertEqual(handleCallCount, 1)
        XCTAssertEqual(lastMessage?.id, message.id)
        XCTAssertEqual(lastData?["url"] as? String, "myapp://screen")
        XCTAssertFalse(openCalled)
    }

    func testButtonLinkHandlerReceivesRendererDataAsIs() {
        var lastData: [String: Any]?
        let data: NSDictionary = ["url": "https://example.com", "extra": "value"]

        let dispatcher = OverlayActionDispatcher(
            handlerForType: { _ in { _, payload in lastData = payload } },
            openURL: { _ in },
            logError: { _ in }
        )

        dispatcher.performButtonLink(message: makeMessage(), data: data)

        XCTAssertEqual(lastData?["url"] as? String, "https://example.com")
        XCTAssertEqual(lastData?["extra"] as? String, "value")
    }

    // MARK: - Fail-safe

    func testThrowingHandlerLogsErrorAndDoesNotOpenURL() {
        var loggedMessage: String?
        var openCalled = false
        struct TestError: Error {}

        let dispatcher = OverlayActionDispatcher(
            handlerForType: { _ in { _, _ in throw TestError() } },
            openURL: { _ in openCalled = true },
            logError: { loggedMessage = $0 }
        )

        dispatcher.performButtonLink(message: makeMessage(), data: makeLinkData())

        XCTAssertNotNil(loggedMessage)
        XCTAssertTrue(loggedMessage?.contains("overlay action handler") ?? false)
        XCTAssertFalse(openCalled)
    }

    // MARK: - Per-type registration

    func testRegisteredHandlerPreventsDefault() {
        var handleCallCount = 0
        var defaultCalled = false

        let dispatcher = OverlayActionDispatcher(
            handlerForType: { type in
                type == .buttonLink ? { _, _ in handleCallCount += 1 } : nil
            },
            openURL: { _ in },
            logError: { _ in }
        )

        dispatcher.performAction(
            type: .buttonLink,
            message: makeMessage(),
            data: ["url": "https://example.com"]
        ) {
            defaultCalled = true
        }

        XCTAssertEqual(handleCallCount, 1)
        XCTAssertFalse(defaultCalled)
    }

    func testClearedHandlerRestoresDefaultOpen() {
        var handler: OverlayActionHandler? = { _, _ in }
        var openedURL: URL?

        let dispatcher = OverlayActionDispatcher(
            handlerForType: { _ in handler },
            openURL: { openedURL = $0 },
            logError: { _ in }
        )

        dispatcher.performButtonLink(message: makeMessage(), data: makeLinkData())
        XCTAssertNil(openedURL)

        handler = nil
        dispatcher.performButtonLink(
            message: makeMessage(),
            data: makeLinkData(url: "https://restored.example")
        )

        XCTAssertEqual(openedURL?.absoluteString, "https://restored.example")
    }
}

//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

/// Answers the scheduled (v2) and immediate (v1) fetches with set bodies, straight away.
private final class FakeHttpClient: KSHttpClient {
    var scheduledBody: [String: Any] = ["messages": [], "nextFetchInSeconds": 3600]
    var immediateBody: [String: Any]?
    private(set) var immediateFetches = 0

    func sendRequest(_ method: KSHttpMethod, toPath path: String, data: Any?, authUserId: String?, onSuccess: @escaping KSHttpSuccessBlock, onFailure: @escaping KSHttpFailureBlock) {
        if path.contains("/scheduled/") {
            onSuccess(nil, scheduledBody)
        } else {
            immediateFetches += 1
            onSuccess(nil, immediateBody)
        }
    }

    func invalidateSessionCancellingTasks(_ cancel: Bool) {}
}

/// Records what the manager tells the session manager, instead of acting on it.
private final class RecordingSessionManager: OverlayMessagingSessionManager {
    private(set) var calls: [String] = []

    init() {
        super.init(sessionLengthMinutes: 60, deferDelayMinutes: 60, listener: {})
    }

    override func onFetchResult(nextFetchInSeconds: Int64) {
        calls.append("onFetchResult(\(nextFetchInSeconds))")
    }

    override func release(_ outcome: Outcome, displayedMessageId: Int64?) {
        calls.append("release(\(outcome))")
    }

    override func onDisplayed(messageId: Int64) {
        calls.append("onDisplayed(\(messageId))")
    }
}

/// Answers each message the same way, and counts how often it was asked.
private final class Interceptor: OverlayMessagingInterceptor {
    private let answer: (OverlayMessagingInterceptorCallback) -> Void
    private(set) var calls = 0

    init(_ answer: @escaping (OverlayMessagingInterceptorCallback) -> Void) {
        self.answer = answer
    }

    func onMessageLoaded(_ message: OverlayMessagingMessage, callback: OverlayMessagingInterceptorCallback) {
        calls += 1
        answer(callback)
    }

    func getTimeoutMs() -> Int { 1 }
}

final class OverlayMessagingManagerTests: XCTestCase {

    private static let message: [String: Any] = ["id": 1, "content": ["ver": 1, "html": "<p>hi</p>"]]

    private var http: FakeHttpClient!
    private var session: RecordingSessionManager!
    private var manager: OverlayMessagingManager!
    private var events: [String] = []

    override func setUp() {
        super.setUp()
        http = FakeHttpClient()
        session = RecordingSessionManager()
        events = []
        manager = OverlayMessagingManager(httpClient: http, urlBuilder: UrlBuilder(storage: KeyValPersistenceHelper.self),
                                          sessionManager: session,
                                          trackEventImmediately: { [unowned self] type, props in
                                              self.events.append("\(type):\(props?["outcome"] ?? "")")
                                          })
        // Messages to show stay queued, so no presenter is created
        manager.setHidden(true)
    }

    private func scheduledReturns(_ message: [String: Any]?, nextFetchInSeconds: Int64) {
        http.scheduledBody = ["messages": message.map { [$0] } ?? [], "nextFetchInSeconds": nextFetchInSeconds]
    }

    /// The session manager found a scheduled fetch due, and took its slot.
    private func triggerScheduled() {
        manager.onTriggerReceived(.session)
        idleMain()
    }

    private func idleMain() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }

    private func intercepted(_ outcome: String) -> [String] {
        ["\(OptimobileEvent.OM_INTERCEPTED.rawValue):\(outcome)"]
    }

    // MARK: - scheduled fetch

    func test_reportsNextFetchAndReleasesDoneWhenNothingIsReturned() {
        scheduledReturns(nil, nextFetchInSeconds: 2040)

        triggerScheduled()

        XCTAssertEqual(session.calls, ["onFetchResult(2040)", "release(done)"])
        XCTAssertEqual(http.immediateFetches, 0)
    }

    func test_releasesDoneOnADiscardAfterTrackingIt() {
        manager.setInterceptor(Interceptor { $0.discard() })
        scheduledReturns(Self.message, nextFetchInSeconds: 0)

        triggerScheduled()

        XCTAssertEqual(session.calls, ["onFetchResult(0)", "release(done)"])
        XCTAssertEqual(events, intercepted("discard"))
    }

    func test_releasesDeferredOnADeferAndOffersTheMessageAgain() {
        let interceptor = Interceptor { $0.deferMessage() }
        manager.setInterceptor(interceptor)
        scheduledReturns(Self.message, nextFetchInSeconds: 0)

        triggerScheduled()
        XCTAssertEqual(session.calls, ["onFetchResult(0)", "release(deferred)"])

        triggerScheduled()
        XCTAssertEqual(interceptor.calls, 2)
    }

    func test_releasesDeferredOnATimeoutAndOffersTheMessageAgain() {
        let interceptor = Interceptor { _ in /* never answers */ }
        manager.setInterceptor(interceptor)
        scheduledReturns(Self.message, nextFetchInSeconds: 0)

        triggerScheduled()
        XCTAssertEqual(session.calls, ["onFetchResult(0)", "release(deferred)"])
        XCTAssertEqual(events, intercepted("timeout"))

        triggerScheduled()
        XCTAssertEqual(interceptor.calls, 2)
    }

    func test_keepsTheSlotForAMessageToShow() {
        manager.setInterceptor(Interceptor { $0.show() })
        scheduledReturns(Self.message, nextFetchInSeconds: 0)

        triggerScheduled()

        XCTAssertEqual(session.calls, ["onFetchResult(0)"])
        XCTAssertEqual(events, intercepted("show"))
    }

    func test_releasesDeferredOnAMessageAlreadyHandledInThisProcess() {
        let interceptor = Interceptor { $0.show() }
        manager.setInterceptor(interceptor)
        scheduledReturns(Self.message, nextFetchInSeconds: 0)
        triggerScheduled()

        triggerScheduled()

        XCTAssertEqual(session.calls, ["onFetchResult(0)", "onFetchResult(0)", "release(deferred)"])
        XCTAssertEqual(interceptor.calls, 1)
    }

    // MARK: - immediate messages

    func test_immediateMessagesDoNotTouchTheSession() {
        http.immediateBody = Self.message

        manager.onTriggerReceived(.immediate)
        idleMain()

        XCTAssertEqual(http.immediateFetches, 1)
        XCTAssertEqual(session.calls, [])
    }

    func test_immediateMessagesDoNotTouchTheSessionWhenDeferred() {
        manager.setInterceptor(Interceptor { $0.deferMessage() })
        http.immediateBody = Self.message

        manager.onTriggerReceived(.immediate)
        idleMain()

        XCTAssertEqual(session.calls, [])
    }

    func test_immediateMessagesTakeOneSlotOfTheirOwn() {
        http.immediateBody = Self.message

        manager.onTriggerReceived(.immediate)
        idleMain()
        manager.onTriggerReceived(.immediate)
        idleMain()

        XCTAssertEqual(http.immediateFetches, 1)
    }
}

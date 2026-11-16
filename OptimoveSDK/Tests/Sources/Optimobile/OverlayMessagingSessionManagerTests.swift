//  Copyright © 2026 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

/// Fires its work once the test's clock reaches the planned time.
private final class FakeScheduler: OverlayMessagingScheduler {
    private var pending: (fireAt: TimeInterval, work: () -> Void)?
    private let clock: () -> TimeInterval

    init(clock: @escaping () -> TimeInterval) {
        self.clock = clock
    }

    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) {
        pending = (clock() + delay, work)
    }

    func cancel() {
        pending = nil
    }

    func runDue() {
        while let (fireAt, work) = pending, fireAt <= clock() {
            pending = nil
            work()
        }
    }
}

final class OverlayMessagingSessionManagerTests: XCTestCase {

    private static let second: TimeInterval = 1
    private static let ms: TimeInterval = 0.001
    private static let minute: TimeInterval = 60
    private static let hour: TimeInterval = 3600
    private static let day: TimeInterval = 24 * hour
    private static let settle: TimeInterval = 10
    // 2026-10-28T10:00:00Z
    private static let tenAm: TimeInterval = 1_793_181_600

    private static let suiteName = "OverlayMessagingSessionManagerTests"
    private static let startKey = "optimove_om_last_session_start"
    private static let countKey = "optimove_om_session_count"

    private var defaults: UserDefaults!
    private var now: TimeInterval = 0
    private var fetches = 0
    private var scheduler: FakeScheduler!
    // The managers a test made: the scheduled work holds them weakly, as in the app, where the SDK holds them
    private var managers: [OverlayMessagingSessionManager] = []

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: Self.suiteName)
        defaults.removePersistentDomain(forName: Self.suiteName)
        now = Self.tenAm
        fetches = 0
        scheduler = FakeScheduler(clock: { [unowned self] in self.now })
        managers = []
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: Self.suiteName)
        super.tearDown()
    }

    private func makeManager(_ sessionLengthMinutes: Int = 60) -> OverlayMessagingSessionManager {
        let manager = OverlayMessagingSessionManager(sessionLengthMinutes: sessionLengthMinutes, deferDelayMinutes: 60,
                                       listener: { [unowned self] in self.fetches += 1 },
                                       defaults: defaults, clock: { [unowned self] in self.now }, scheduler: scheduler)
        managers.append(manager)
        return manager
    }

    private func advance(_ seconds: TimeInterval) {
        now += seconds
        scheduler.runDue()
    }

    /// A manager in the foreground whose first fetch, at 10:00, returned `nextFetchInSeconds` and a message the caller
    /// is still handling: the slot is taken until `release`.
    private func fetching(_ nextFetchInSeconds: Int64, sessionLengthMinutes: Int = 60) -> OverlayMessagingSessionManager {
        let manager = makeManager(sessionLengthMinutes)
        manager.appEnteredForeground()
        XCTAssertEqual(fetches, 1)
        manager.onFetchResult(nextFetchInSeconds: nextFetchInSeconds)
        fetches = 0
        return manager
    }

    /// As `fetching`, with nothing to show: the slot is free again.
    private func fetched(_ nextFetchInSeconds: Int64) -> OverlayMessagingSessionManager {
        let manager = fetching(nextFetchInSeconds)
        manager.release(.done, displayedMessageId: nil)
        return manager
    }

    /// As `fetching`, with the message displayed at 10:00 and still open.
    private func displayed(_ nextFetchInSeconds: Int64, sessionLengthMinutes: Int = 60) -> OverlayMessagingSessionManager {
        let manager = fetching(nextFetchInSeconds, sessionLengthMinutes: sessionLengthMinutes)
        manager.onDisplayed(messageId: 1)
        return manager
    }

    /// As `fetching`, with the message not shown.
    private func deferred(_ nextFetchInSeconds: Int64) -> OverlayMessagingSessionManager {
        let manager = fetching(nextFetchInSeconds)
        manager.release(.deferred, displayedMessageId: nil)
        return manager
    }

    // MARK: - session

    func test_aDisplayStartsTheSessionAndHoldsTheNextFetchUntilItEnds() {
        let manager = displayed(0)
        manager.release(.done, displayedMessageId: nil)

        advance(Self.hour - Self.ms)
        XCTAssertEqual(fetches, 0)
        advance(Self.ms)
        XCTAssertEqual(fetches, 1)
        XCTAssertEqual(defaults.double(forKey: Self.startKey), Self.tenAm)
        XCTAssertEqual(defaults.integer(forKey: Self.countKey), 1)
    }

    func test_noSessionStartsWhenNothingIsDisplayed() {
        fetching(0).release(.done, displayedMessageId: nil)
        advance(Self.settle)

        XCTAssertEqual(fetches, 1)
        XCTAssertNil(defaults.object(forKey: Self.startKey))
    }

    func test_theSessionSurvivesARestart() {
        _ = displayed(0)

        advance(2 * Self.minute)
        let restarted = makeManager()
        restarted.appEnteredForeground()
        XCTAssertEqual(fetches, 0)

        advance(Self.hour)
        XCTAssertEqual(fetches, 1)
    }

    func test_aStartWithoutACountFromEarlierVersionsHasRoom() {
        defaults.set(Self.tenAm - Self.minute, forKey: Self.startKey)

        makeManager().appEnteredForeground()

        XCTAssertEqual(fetches, 1)
    }

    func test_theSameMessageDisplayedAgainIsCountedOnce() {
        let manager = displayed(0)

        manager.onDisplayed(messageId: 1)

        XCTAssertEqual(defaults.integer(forKey: Self.countKey), 1)
    }

    func test_aMessageDisplayedAgainAfterItsReleaseCountsAgain() {
        // e.g. it failed to render after opening, was deferred, and came back
        let manager = displayed(0)
        manager.release(.deferred, displayedMessageId: 1)

        manager.onDisplayed(messageId: 1)

        XCTAssertEqual(defaults.integer(forKey: Self.countKey), 2)
    }

    func test_differentMessagesEachCount() {
        let manager = displayed(0)

        manager.onDisplayed(messageId: 2)

        XCTAssertEqual(defaults.integer(forKey: Self.countKey), 2)
    }

    // MARK: - slot

    func test_fetchesOneAtATimeEvenWhenDue() {
        let manager = fetching(0)
        manager.onSignal(nextFetchInSeconds: 0)
        manager.appEnteredBackground()
        manager.appEnteredForeground()
        advance(Self.day)
        XCTAssertEqual(fetches, 0)

        manager.release(.done, displayedMessageId: nil)
        advance(Self.settle)
        XCTAssertEqual(fetches, 1)
    }

    func test_onReleaseKeepsAPlannedTimeThatIsStillAhead() {
        _ = fetched(600)
        XCTAssertEqual(fetches, 0)

        advance(600)
        XCTAssertEqual(fetches, 1)
    }

    // MARK: - fetch triggers

    func test_fetchesOnEnteringTheForeground() {
        makeManager().appEnteredForeground()
        XCTAssertEqual(fetches, 1)
    }

    func test_doesNotFetchInTheBackground() {
        let manager = fetched(600)
        manager.appEnteredBackground()
        advance(Self.day)
        XCTAssertEqual(fetches, 0)
    }

    func test_fetchesOnReturningToTheForegroundAfterThePlannedTime() {
        let manager = fetched(600)
        manager.appEnteredBackground()
        advance(20 * Self.minute)

        manager.appEnteredForeground()
        XCTAssertEqual(fetches, 1)
    }

    func test_keepsThePlannedTimeOnReturningToTheForegroundBeforeIt() {
        let manager = fetched(600)
        manager.appEnteredBackground()
        advance(5 * Self.minute)
        manager.appEnteredForeground()
        XCTAssertEqual(fetches, 0)

        advance(5 * Self.minute)
        XCTAssertEqual(fetches, 1)
    }

    func test_resetEndsTheSessionAndFetches() {
        let manager = displayed(3600)
        manager.release(.done, displayedMessageId: nil)

        manager.reset()

        XCTAssertNil(defaults.object(forKey: Self.startKey))
        XCTAssertNil(defaults.object(forKey: Self.countKey))
        XCTAssertEqual(fetches, 1)
    }

    func test_resetWhileTheSlotIsFullFetchesAfterRelease() {
        let manager = displayed(3600)
        manager.reset()
        XCTAssertEqual(fetches, 0)

        manager.release(.done, displayedMessageId: nil)
        advance(Self.settle)
        XCTAssertEqual(fetches, 1)
    }

    func test_resetDuringTheFetchIsNotUndoneByItsResult() {
        let manager = makeManager()
        manager.appEnteredForeground()
        fetches = 0

        manager.reset()
        manager.onFetchResult(nextFetchInSeconds: 3600)
        manager.release(.done, displayedMessageId: nil)
        advance(Self.settle)
        XCTAssertEqual(fetches, 1)
    }

    // MARK: - planned fetch time

    func test_plansNextFetchInSecondsAhead() {
        _ = fetched(2040)

        advance(2040 - Self.ms)
        XCTAssertEqual(fetches, 0)
        advance(Self.ms)
        XCTAssertEqual(fetches, 1)
    }

    func test_afterDoneWaitsTheSettleDelayEvenFor0() {
        fetching(0).release(.done, displayedMessageId: nil)

        advance(Self.settle - Self.ms)
        XCTAssertEqual(fetches, 0)
        advance(Self.ms)
        XCTAssertEqual(fetches, 1)
    }

    func test_waitsForTheSessionEndWhenFullEvenIfTheNextMessageIsDueSooner() {
        displayed(600).release(.done, displayedMessageId: nil)

        advance(Self.hour - Self.ms)
        XCTAssertEqual(fetches, 0)
        advance(Self.ms)
        XCTAssertEqual(fetches, 1)
    }

    func test_waitsForNextFetchInSecondsWhenLaterThanTheSessionEnd() {
        displayed(3 * 3600).release(.done, displayedMessageId: nil)

        advance(3 * Self.hour - Self.ms)
        XCTAssertEqual(fetches, 0)
        advance(Self.ms)
        XCTAssertEqual(fetches, 1)
    }

    func test_fetchesAtCloseWhenTheMessageStayedOpenPastTheSessionEnd() {
        let manager = displayed(0)
        advance(90 * Self.minute)
        XCTAssertEqual(fetches, 0)

        manager.release(.done, displayedMessageId: nil)
        advance(Self.settle)
        XCTAssertEqual(fetches, 1)
    }

    func test_withSessionLength0ADueFetchRunsAtTheClose() {
        let manager = displayed(0, sessionLengthMinutes: 0)

        manager.release(.done, displayedMessageId: nil)
        advance(Self.settle)
        XCTAssertEqual(fetches, 1)
    }

    // MARK: - scheduled Signals

    func test_aSignalMovesThePlannedFetchEarlier() {
        let manager = fetched(20 * 3600)

        manager.onSignal(nextFetchInSeconds: 3600)
        XCTAssertEqual(fetches, 0)

        advance(Self.hour)
        XCTAssertEqual(fetches, 1)
    }

    func test_aSignalFor0FetchesStraightAway() {
        fetched(20 * 3600).onSignal(nextFetchInSeconds: 0)
        XCTAssertEqual(fetches, 1)
    }

    func test_aSignalIsIgnoredWhenThePlannedFetchIsAlreadyEarlier() {
        let manager = fetched(600)
        manager.onSignal(nextFetchInSeconds: 3600)

        advance(600)
        XCTAssertEqual(fetches, 1)
    }

    func test_aSignalDuringTheSettleDelayFetchesStraightAway() {
        let manager = fetched(20 * 3600)
        manager.onSignal(nextFetchInSeconds: 0)
        XCTAssertEqual(fetches, 1)
    }

    func test_aSignalDuringTheFetchWinsOverALaterResult() {
        let manager = makeManager()
        manager.appEnteredForeground()
        fetches = 0

        manager.onSignal(nextFetchInSeconds: 600)
        manager.onFetchResult(nextFetchInSeconds: 20 * 3600)
        manager.release(.done, displayedMessageId: nil)
        XCTAssertEqual(fetches, 0)

        advance(600)
        XCTAssertEqual(fetches, 1)
    }

    func test_aSignalDuringAFullSessionBringsTheFetchToTheSessionEnd() {
        let manager = displayed(20 * 3600)
        manager.release(.done, displayedMessageId: nil)

        manager.onSignal(nextFetchInSeconds: 0)
        XCTAssertEqual(fetches, 0)

        advance(Self.hour)
        XCTAssertEqual(fetches, 1)
    }

    // MARK: - defer delay

    func test_deferredIgnoresTheServers0AndWaitsTheDelay() {
        _ = deferred(0)

        advance(Self.hour - Self.ms)
        XCTAssertEqual(fetches, 0)
        advance(Self.ms)
        XCTAssertEqual(fetches, 1)
    }

    func test_deferredKeepsAServerTimeThatIsSooner() {
        _ = deferred(600)
        advance(600)
        XCTAssertEqual(fetches, 1)
    }

    func test_deferredCutsALaterServerTimeToTheDelay() {
        _ = deferred(3 * 3600)
        advance(Self.hour)
        XCTAssertEqual(fetches, 1)
    }

    func test_aSignalEndsTheDeferDelayEarly() {
        let manager = deferred(0)
        advance(10 * Self.minute)

        manager.onSignal(nextFetchInSeconds: 300)
        advance(5 * Self.minute)
        XCTAssertEqual(fetches, 1)
    }
}

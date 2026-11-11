//  Copyright © 2025 Optimove. All rights reserved.

import Foundation
import UIKit

/// Owns scheduled fetching: decides when the next one is due, and runs at most one at a time. Inputs:
/// - the session: started by a displayed message when none is active, lasting the session length, holding at most
///   one display. Persisted so it survives restarts: the start under the key earlier versions used for it, and the
///   count next to it. Nothing but a display starts or fills it.
/// - `nextFetchInSeconds` from a fetch (the server's, or the request service's backoff after a failure) or a Signal.
///   The server already caps it, so there is no client-side refresh cap.
/// - the slot: one place, taken when `onFetchDue` is called, until the caller calls `release` once that message is
///   done with. Nothing is fetched while it's full; `release` then fetches if the planned time has passed.
///
/// The planned fetch is the later of the two times when the session is full. `onFetchDue` is called when it's due,
/// the slot has room and the app is in the foreground. Planning starts with `start()`. All calls are on the main thread.
class OverlayMessagingSessionManager {

    typealias FetchDueListener = () -> Void
    typealias Clock = () -> TimeInterval

    /// How a scheduled fetch ended, for `release`:
    /// - done: the message was closed or discarded (the server deletes it), or nothing was fetched; the server's next
    ///   time stands, but no sooner than the settle delay, so a close or discard has time to reach the server.
    /// - deferred: the message is still on the server and wasn't shown (deferred, timed out, failed to render, or it
    ///   was already seen); wait the defer delay, so the same message doesn't come straight back.
    enum Outcome {
        case done, deferred
    }

    private static let displaysPerSession = 1
    private static let slotCapacity = 1
    // After done, best effort time for the server to apply a close or discard before the next fetch
    private static let settleDelay: TimeInterval = 10
    private static let sessionStartKey = "optimove_om_last_session_start"
    private static let sessionCountKey = "optimove_om_session_count"

    private let defaults: UserDefaults
    private let listener: FetchDueListener
    private let clock: Clock
    private let scheduler: OverlayMessagingScheduler
    private let duration: TimeInterval
    private let deferDelay: TimeInterval
    // When the server (or a Signal) says to fetch next; 0 means straight away, as at start, and
    // infinity not yet known, while a fetch is in flight
    private var nextFetchAt: TimeInterval = 0
    // The display slot: scheduled fetches, or the messages they returned, in progress
    private var slotCount = 0
    // Displayed messages counted toward the session and still on screen, so a message reported as displayed again
    // doesn't count twice toward the session limit
    private var countedMessageIds = Set<Int64>()
    private var appInForeground = false

    init(sessionLengthMinutes: Int,
         deferDelayMinutes: Int,
         listener: @escaping FetchDueListener,
         defaults: UserDefaults = .standard,
         clock: @escaping Clock = { Date().timeIntervalSince1970 },
         scheduler: OverlayMessagingScheduler = MainQueueScheduler()) {
        self.duration = TimeInterval(sessionLengthMinutes) * 60
        self.deferDelay = TimeInterval(deferDelayMinutes) * 60
        self.listener = listener
        self.defaults = defaults
        self.clock = clock
        self.scheduler = scheduler
    }

    // MARK: - Internal

    /// Follows the app's foreground and background, starting with the current state.
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredForeground),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteredBackground),
                                               name: UIApplication.didEnterBackgroundNotification, object: nil)
        if UIApplication.shared.applicationState == .active {
            appEnteredForeground()
        }
    }

    /// The result of a scheduled fetch: when to fetch next. A Signal or `reset` during the fetch keeps its time if
    /// it's sooner: the server may have read the messages before the Signal's one was created.
    func onFetchResult(nextFetchInSeconds: Int64) {
        nextFetchAt = min(nextFetchAt, clock() + TimeInterval(nextFetchInSeconds))
        plan()
    }

    /// A scheduled message was displayed: starts a session if none is active, and counts toward it, once while it
    /// stays on screen.
    func onDisplayed(messageId: Int64) {
        guard countedMessageIds.insert(messageId).inserted else { return }
        let session = activeSession()
        writeSession(session.map { Session(start: $0.start, count: $0.count + 1) } ?? Session(start: clock(), count: 1))
        plan()
    }

    /// The scheduled fetch started by `onFetchDue`, and its message, are done with: frees the slot and fetches if the
    /// planned time has passed. On deferred it first holds back for the defer delay, unless the server's next time is
    /// still ahead and sooner (a different message is due then). The server's 0 ("more due") has passed by then and
    /// is ignored: fetching at once would return the same message again. On done it holds back for the settle delay
    /// at least. `displayedMessageId` is the message, if it was displayed: a later display of it counts again.
    func release(_ outcome: Outcome, displayedMessageId: Int64?) {
        if let displayedMessageId = displayedMessageId {
            countedMessageIds.remove(displayedMessageId)
        }
        slotCount = max(0, slotCount - 1)
        let now = clock()
        switch outcome {
        case .deferred:
            let end = now + deferDelay
            nextFetchAt = nextFetchAt > now ? min(nextFetchAt, end) : end
        case .done:
            nextFetchAt = max(nextFetchAt, now + Self.settleDelay)
        }
        plan()
    }

    /// A scheduled Signal: moves the next fetch earlier. During a full session the fetch still waits for the session end.
    func onSignal(nextFetchInSeconds: Int64) {
        nextFetchAt = min(nextFetchAt, clock() + TimeInterval(nextFetchInSeconds))
        plan()
    }

    /// Ends the session and fetches, for `resetSession()` and user change.
    func reset() {
        defaults.removeObject(forKey: Self.sessionStartKey)
        defaults.removeObject(forKey: Self.sessionCountKey)
        nextFetchAt = 0
        plan()
    }

    // MARK: - Lifecycle

    @objc func appEnteredForeground() {
        appInForeground = true
        plan()
    }

    @objc func appEnteredBackground() {
        appInForeground = false
        scheduler.cancel()
    }

    // MARK: - Planning

    /// Fetches now if the planned time has passed, otherwise sets the timer for it. Nothing in the background, or while
    /// the slot is full: `release` plans again.
    private func plan() {
        scheduler.cancel()
        guard appInForeground, slotCount < Self.slotCapacity else { return }
        let delay = plannedFetchAt() - clock()
        guard delay <= 0 else {
            scheduler.schedule(after: delay) { [weak self] in self?.plan() }
            return
        }
        slotCount += 1
        // The time that made this fetch due has passed; until the result, only a Signal or reset() sets it
        nextFetchAt = .infinity
        listener()
    }

    private func plannedFetchAt() -> TimeInterval {
        guard let session = activeSession(), session.count >= Self.displaysPerSession else {
            return nextFetchAt
        }
        return max(nextFetchAt, session.start + duration)
    }

    // MARK: - Session

    private struct Session {
        let start: TimeInterval
        let count: Int
    }

    /// A start without a count, as earlier versions stored it, is a session with no display yet.
    private func activeSession() -> Session? {
        let start = defaults.double(forKey: Self.sessionStartKey)
        guard start != 0, clock() < start + duration else { return nil }
        return Session(start: start, count: defaults.integer(forKey: Self.sessionCountKey))
    }

    private func writeSession(_ session: Session) {
        defaults.set(session.start, forKey: Self.sessionStartKey)
        defaults.set(session.count, forKey: Self.sessionCountKey)
    }
}

/// Runs one piece of work after a delay; scheduling again replaces it.
protocol OverlayMessagingScheduler {
    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void)
    func cancel()
}

final class MainQueueScheduler: OverlayMessagingScheduler {
    private var item: DispatchWorkItem?

    func schedule(after delay: TimeInterval, _ work: @escaping () -> Void) {
        cancel()
        let item = DispatchWorkItem(block: work)
        self.item = item
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    func cancel() {
        item?.cancel()
        item = nil
    }
}

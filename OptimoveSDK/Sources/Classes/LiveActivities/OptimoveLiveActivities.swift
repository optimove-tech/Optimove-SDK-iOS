//  Copyright © 2026 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import UIKit

#if canImport(ActivityKit)
    import ActivityKit
#endif

/// How the SDK first noticed a Live Activity (`detectionSource` on `k.liveActivity.started`).
public enum OptimoveLiveActivityDetectionSource: String {
    /// Present in `Activity.activities` when observation began.
    case existingOnLaunch
    /// Received from `Activity.activityUpdates`.
    case activityUpdates
}

/// Collects push-to-start tokens and reports Optimove-started Live Activities.
public final class OptimoveLiveActivities {
    public static let shared = OptimoveLiveActivities()

    private let lock = NSLock()
    private var isStarted = false
    private var registrations: [OptimoveLiveActivityRegistration] = []
    private var tokensByAttributesType: [String: String] = [:]
    private var reportedActivityKeys: Set<String> = []
    private var observationCancellations: [() -> Void] = []

    private init() {}

    /// Latest push-to-start token per attributes type name (lowercase hex).
    public var pushToStartTokens: [String: String] {
        lock.lock()
        defer { lock.unlock() }
        return tokensByAttributesType
    }

    /// Attributes type names registered in `enableLiveActivities`.
    public var registeredAttributesTypeNames: [String] {
        lock.lock()
        defer { lock.unlock() }
        return registrations.map(\.attributesTypeName)
    }

    // MARK: - Start

    static func start(with config: OptimoveConfig) {
        let registrations = config.liveActivityRegistrations

        guard !registrations.isEmpty else {
            Logger.error("""
            Live Activities is enabled but no ActivityAttributes types were registered. \
            Call enableLiveActivities(YourAttributes.self) on OptimoveConfigBuilder.
            """)
            return
        }

        guard config.isOptimobileConfigured() else {
            Logger.error("""
            Live Activities requires Optimobile. Registered types: \
            \(registrations.map(\.attributesTypeName).joined(separator: ", ")).
            """)
            return
        }

        shared.startObserving(registrations)
    }

    private func startObserving(_ registrations: [OptimoveLiveActivityRegistration]) {
        lock.lock()
        if isStarted {
            lock.unlock()
            Logger.debug("Live Activities: already observing, ignoring repeat start.")
            return
        }
        isStarted = true
        self.registrations = registrations
        reportedActivityKeys = Self.loadReportedActivityKeys()
        lock.unlock()

        guard #available(iOS 18.0, *) else {
            Logger.warn("""
            Live Activities requires iOS 18.0 or newer. \
            Running \(ProcessInfo.processInfo.operatingSystemVersionString) — nothing will be observed.
            """)
            return
        }

        Logger.info("""
        Live Activities: starting observation for \
        \(registrations.map(\.attributesTypeName).joined(separator: ", ")).
        """)

        for registration in registrations {
            registration.observe(self)
        }
    }

    func stopObserving() {
        lock.lock()
        let cancellations = observationCancellations
        observationCancellations.removeAll()
        isStarted = false
        lock.unlock()

        cancellations.forEach { $0() }
        Logger.debug("Live Activities: cancelled \(cancellations.count) observation task(s).")
    }

    // MARK: - Observation

    #if canImport(ActivityKit)
        @available(iOS 18.0, *)
        func observe<Attributes: ActivityAttributes & OptimoveLiveActivityAttributes>(_ type: Attributes.Type) {
            let tokenTask = observePushToStartToken(type)
            let activityTask = observeActivities(type)

            lock.lock()
            observationCancellations.append { tokenTask.cancel() }
            observationCancellations.append { activityTask.cancel() }
            lock.unlock()
        }

        @available(iOS 18.0, *)
        private func observePushToStartToken<Attributes: ActivityAttributes & OptimoveLiveActivityAttributes>(
            _ type: Attributes.Type
        ) -> Task<Void, Never> {
            let attributesTypeName = String(describing: type)

            if let existingToken = Activity<Attributes>.pushToStartToken {
                handlePushToStartToken(
                    hexToken: Optimobile.serializeDeviceToken(existingToken),
                    attributesTypeName: attributesTypeName
                )
            }

            Logger.debug("Live Activities: observing push-to-start token updates for \(attributesTypeName).")
            return Task { [weak self] in
                for await tokenData in Activity<Attributes>.pushToStartTokenUpdates {
                    if Task.isCancelled { break }
                    self?.handlePushToStartToken(
                        hexToken: Optimobile.serializeDeviceToken(tokenData),
                        attributesTypeName: attributesTypeName
                    )
                }
                Logger.warn("Live Activities: pushToStartTokenUpdates for \(attributesTypeName) ended.")
            }
        }

        @available(iOS 18.0, *)
        private func observeActivities<Attributes: ActivityAttributes & OptimoveLiveActivityAttributes>(
            _ type: Attributes.Type
        ) -> Task<Void, Never> {
            let attributesTypeName = String(describing: type)

            return Task { [weak self] in
                let existing = Activity<Attributes>.activities
                Logger.debug("Live Activities: \(existing.count) existing activity(ies) for \(attributesTypeName) at start.")

                self?.pruneReportedActivities(
                    attributesTypeName: attributesTypeName,
                    liveKeys: Set(existing.compactMap { activity in
                        guard let optimoveActivityId = activity.attributes.optimoveActivityId,
                              !optimoveActivityId.isEmpty
                        else {
                            return nil
                        }
                        return Self.activityDedupeKey(
                            attributesTypeName: attributesTypeName,
                            optimoveActivityId: optimoveActivityId
                        )
                    })
                )

                for activity in existing {
                    self?.handleActivity(
                        activityId: activity.id,
                        optimoveActivityId: activity.attributes.optimoveActivityId,
                        attributesTypeName: attributesTypeName,
                        source: .existingOnLaunch
                    )
                }

                Logger.debug("Live Activities: observing activityUpdates for \(attributesTypeName).")
                for await activity in Activity<Attributes>.activityUpdates {
                    if Task.isCancelled { break }
                    self?.handleActivity(
                        activityId: activity.id,
                        optimoveActivityId: activity.attributes.optimoveActivityId,
                        attributesTypeName: attributesTypeName,
                        source: .activityUpdates
                    )
                }
                Logger.warn("Live Activities: activityUpdates for \(attributesTypeName) ended.")
            }
        }
    #endif

    // MARK: - Handling

    private func handlePushToStartToken(hexToken: String, attributesTypeName: String) {
        let storageKey = Self.tokenStorageKey(for: attributesTypeName)
        let persisted = KeyValPersistenceHelper.object(forKey: storageKey) as? String

        lock.lock()
        let alreadyReportedThisSession = tokensByAttributesType[attributesTypeName] == hexToken
        tokensByAttributesType[attributesTypeName] = hexToken
        lock.unlock()

        if alreadyReportedThisSession {
            Logger.debug("Live Activities: push-to-start token for \(attributesTypeName) already reported this session.")
        } else {
            KeyValPersistenceHelper.set(hexToken, forKey: storageKey)

            if persisted == nil {
                Logger.info("Live Activities: first push-to-start token for \(attributesTypeName): \(hexToken)")
            } else if persisted == hexToken {
                Logger.debug("Live Activities: push-to-start token for \(attributesTypeName) unchanged, re-reporting on launch.")
            } else {
                Logger.info("Live Activities: push-to-start token rotated for \(attributesTypeName): \(hexToken)")
            }

            reportPushToStartTokenEvent(hexToken: hexToken, attributesTypeName: attributesTypeName)
        }
    }

    private func handleActivity(
        activityId: String,
        optimoveActivityId: String?,
        attributesTypeName: String,
        source: OptimoveLiveActivityDetectionSource
    ) {
        guard let optimoveActivityId, !optimoveActivityId.isEmpty else {
            Logger.debug("""
            Live Activities: activity \(activityId) (\(attributesTypeName)) has no optimoveActivityId; ignoring.
            """)
            return
        }

        let dedupeKey = Self.activityDedupeKey(
            attributesTypeName: attributesTypeName,
            optimoveActivityId: optimoveActivityId
        )

        lock.lock()
        let isNew = reportedActivityKeys.insert(dedupeKey).inserted
        let snapshot = reportedActivityKeys
        lock.unlock()

        guard isNew else {
            Logger.debug("Live Activities: activity \(activityId) (\(attributesTypeName)) seen again via \(source.rawValue), already reported.")
            return
        }

        Self.persistReportedActivityKeys(snapshot)

        Logger.info("Live Activities: activity started — id \(activityId), type \(attributesTypeName), detected via \(source.rawValue).")
        reportActivityStartedEvent(
            activityId: activityId,
            optimoveActivityId: optimoveActivityId,
            attributesTypeName: attributesTypeName,
            source: source
        )
    }

    private func pruneReportedActivities(attributesTypeName: String, liveKeys: Set<String>) {
        let prefix = "\(attributesTypeName)#"

        lock.lock()
        let before = reportedActivityKeys.count
        reportedActivityKeys = reportedActivityKeys.filter { key in
            guard key.hasPrefix(prefix) else { return true }
            return liveKeys.contains(key)
        }
        let snapshot = reportedActivityKeys
        lock.unlock()

        guard before != snapshot.count else { return }
        Self.persistReportedActivityKeys(snapshot)
        Logger.debug("Live Activities: pruned \(before - snapshot.count) stale activity record(s) for \(attributesTypeName).")
    }

    // MARK: - Event reporting

    private func reportPushToStartTokenEvent(hexToken: String, attributesTypeName: String) {
        guard Optimobile.isInitialized() else {
            Logger.error("Live Activities: cannot report the push-to-start token, Optimobile is not initialized.")
            return
        }

        let properties: [String: Any] = [
            "token": hexToken,
            "attributesType": attributesTypeName,
            "type": Optimobile.sharedInstance.pushNotificationDeviceType,
            "iosTokenType": Optimobile.getTokenType(),
            "bundleId": Bundle.main.infoDictionary?["CFBundleIdentifier"] as Any,
        ]

        track(event: .LIVE_ACTIVITY_PUSH_TO_START_TOKEN_REGISTERED, properties: properties)
    }

    private func reportActivityStartedEvent(
        activityId: String,
        optimoveActivityId: String,
        attributesTypeName: String,
        source: OptimoveLiveActivityDetectionSource
    ) {
        let properties: [String: Any] = [
            "activityId": activityId,
            "optimoveActivityId": optimoveActivityId,
            "attributesType": attributesTypeName,
            "detectionSource": source.rawValue,
        ]

        track(event: .LIVE_ACTIVITY_STARTED, properties: properties)
    }

    private func track(event: OptimobileEvent, properties: [String: Any]) {
        guard Optimobile.isInitialized() else {
            Logger.error("Live Activities: cannot report \(event.rawValue), Optimobile is not initialized.")
            return
        }

        let backgroundTask = LiveActivityBackgroundTask(name: "optimove.liveActivity.flush")

        Optimobile.trackEvent(
            eventType: event.rawValue,
            atTime: Date(),
            properties: properties,
            immediateFlush: true
        ) { error in
            if let error {
                Logger.warn("""
                Live Activities: flushing \(event.rawValue) failed: \(error.localizedDescription).
                """)
            } else {
                Logger.debug("Live Activities: \(event.rawValue) flushed.")
            }
            backgroundTask.end()
        }
    }

    // MARK: - Persistence

    private static let reportedActivitiesStorageKey = "OptimoveLiveActivityReportedActivities"

    private static func tokenStorageKey(for attributesTypeName: String) -> String {
        "OptimoveLiveActivityPushToStartToken_\(attributesTypeName)"
    }

    private static func activityDedupeKey(
        attributesTypeName: String,
        optimoveActivityId: String
    ) -> String {
        "\(attributesTypeName)#\(optimoveActivityId)"
    }

    private static func loadReportedActivityKeys() -> Set<String> {
        Set(KeyValPersistenceHelper.object(forKey: reportedActivitiesStorageKey) as? [String] ?? [])
    }

    private static func persistReportedActivityKeys(_ keys: Set<String>) {
        KeyValPersistenceHelper.set(Array(keys), forKey: reportedActivitiesStorageKey)
    }
}

private final class LiveActivityBackgroundTask {
    private var id: UIBackgroundTaskIdentifier = .invalid
    private let lock = NSLock()

    init(name: String) {
        id = UIApplication.shared.beginBackgroundTask(withName: name) { [weak self] in
            self?.end()
        }
    }

    func end() {
        lock.lock()
        defer { lock.unlock() }
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
    }
}

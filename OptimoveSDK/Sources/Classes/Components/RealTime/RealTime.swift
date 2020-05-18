//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RealTime {

    private struct Constants {
        static let eventBatchLimit = 50
        static let failProtectedEvents = [
            OptimoveKeys.Configuration.setUserId.rawValue,
            OptimoveKeys.Configuration.setEmail.rawValue
        ]
        static let path = "reportEvent"
    }

    private let configuration: RealtimeConfig
    private let realTimeQueue = DispatchQueue(label: "com.optimove.sdk.realtime", qos: .userInitiated)
    private var storage: OptimoveStorage
    private let queue: OptistreamQueue
    private let networking: OptistreamNetworking

    // MARK: - Public

    required init(
        configuration: RealtimeConfig,
        storage: OptimoveStorage,
        networking: OptistreamNetworking,
        queue: OptistreamQueue) {
        self.configuration = configuration
        self.storage = storage
        self.networking = networking
        self.queue = queue
    }

}

extension RealTime: OptistreamComponent {

    func handle(_ operation: OptistreamOperation) throws {
        let handleOperationOnQueue: () -> Void = { [weak self] in
            guard let self = self else { return }
            switch operation {
            case let .report(events: events):
                let allowedEvents = events.filter(self.isAllowedToReport)
                guard !allowedEvents.isEmpty else { break }
                self.report(allowedEvents)
            default:
                break
            }
        }
        realTimeQueue.async(execute: handleOperationOnQueue)
    }
}

private extension RealTime {

    func isAllowedToReport(_ event: OptistreamEvent) -> Bool {
        return event.metadata.realtime && !configuration.isEnableRealtimeThroughOptistream
    }

    func report(_ events: [OptistreamEvent]) {
        if queue.isEmpty {
            /// Simply send incoming events if the queue is empty
            sentReportEvent(events)
        } else {
            let failProtectedEvents = queue.first(limit: max(Constants.eventBatchLimit - events.count, 1))
            /// Check if we have intersection between `failProtectedEvents` and incoming events.
            if events.filter(isFailProtectedEvent).isEmpty {
                /// If no intersection found – merge them and send.
                sentReportEvent(failProtectedEvents + events)
            } else {
                /// If intersection found, we have to separate the outdated `failProtectedEvents` from the up-to-dated `failProtectedEvents`,
                /// and keep only up-to-dated, if they're left.
                let toSend = failProtectedEvents.filter { (event) -> Bool in
                    return events.filter { $0.event == event.event }.isEmpty
                }
                /// Remove the outdated `failProtectedEvents` from a queue.
                let toRemove = failProtectedEvents.filter { !toSend.contains($0) }
                queue.remove(events: toRemove)
                /// Send the up-to-dated `failProtectedEvents` merged with incoming events to RT.
                sentReportEvent(toSend + events)
            }
        }
    }

}

// MARK: - Private

private extension RealTime {

    // MARK: Send report

    func sentReportEvent(_ events: [OptistreamEvent]) {
        networking.send(events: events, path: Constants.path) { [weak self] (result) in
            guard let self = self else { return }
            self.realTimeQueue.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case .success():
                    self.onSuccess(events)
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                    self.onError(events)
                }
            }
        }
    }

    func onSuccess(_ events: [OptistreamEvent]) {
        queue.remove(events: events.filter(isFailProtectedEvent))
    }

    func onError(_ events: [OptistreamEvent]) {
        queue.enqueue(events: events.filter(isFailProtectedEvent))
    }

    func isFailProtectedEvent(_ event: OptistreamEvent) -> Bool {
        return Constants.failProtectedEvents.contains(event.event)
    }

}

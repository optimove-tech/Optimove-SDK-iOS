//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RealTime {

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
            case let .report(event: event):
                guard self.isAllowedToReport(event) else { break }
                self.report(event)
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

    func report(_ event: OptistreamEvent) {
//        shouldPersist(event)
    }

}

// MARK: - Private

private extension RealTime {

    //    // MARK: Transforming an event
    //
    //    func createEventContext(event: OptistreamEvent, config: EventsConfig) -> RealTimeEventContext {
    //        switch event.event {
    //        case OptimoveKeys.Configuration.setUserId.rawValue:
    //            return RealTimeEventContext(
    //                event: event,
    //                config: config,
    //                type: .setUserID
    //            )
    //        case OptimoveKeys.Configuration.setEmail.rawValue:
    //            return RealTimeEventContext(
    //                event: event,
    //                config: config,
    //                type: .setUserEmail
    //            )
    //        default:
    //            return RealTimeEventContext(
    //                event: event,
    //                config: config,
    //                type: .regular
    //            )
    //        }
    //    }

    // MARK: Prepare before send a report

    //    func report(context: RealTimeEventContext, retryFailedEvents: Bool) throws {
    //        if retryFailedEvents {
    //            try retryUserDataIfNeeded(context: context)
    //        }
    //        sentReportEvent(context: context)
    //    }

    // MARK: Retry

    /// Verify that failed set_user_id is dispatched before failed set_email
    /// and before any custom event.
    /// This is requirment from the Server-side.
    //    func retryUserDataIfNeeded(context: RealTimeEventContext) throws {
    //        // Do not invoke retry on a new UserID
    //        if context.type != .setUserID {
    //            try retrySetUserIdEventIfNeeded()
    //        }
    //        // Do not invoke retry on a new UserEmail
    //        if context.type != .setUserEmail {
    //            try retrySetUserEmailIfNeeded()
    //        }
    //    }

    //    func retrySetUserIdEventIfNeeded() throws {
    //        if storage.realtimeSetUserIdFailed {
    //            try reportUserId()
    //        }
    //    }
    //
    //    func retrySetUserEmailIfNeeded() throws {
    //        if storage.realtimeSetEmailFailed {
    //            try reportUserEmail()
    //        }
    //    }

    // MARK: Send report

    func sentReportEvent(_ event: OptistreamEvent) {
        networking.send(events: [event]) { [weak self] (result) in
            guard let self = self else { return }
            self.realTimeQueue.async { [weak self] in
                guard let self = self else { return }
                switch result {
                case let .success(response):
                    Logger.info(response.message)
                    self.onSuccess(event)
                case let .failure(error):
                    Logger.error(error.localizedDescription)
                    self.onError(event)
                }
            }
        }
    }


    //            do {
    //                /// The `semaphore.wait` added as the way to keep order in realtime events without possible race conditions produced by a network handling.
    //                semaphore.wait()
    //                let realtimeEvent = try eventBuilder.createEvent(context: context, realtimeToken: realtimeToken)
    //                try networking.report(event: realtimeEvent) { (result) in
    //                    semaphore.signal()
    //                    switch result {
    //                    case let .success(json):
    //                        hanlder.handleOnSuccess(context, json: json)
    //                    case let .failure(error):
    //                        hanlder.handleOnError(context, error: error)
    //                    }
    //                }
    //            } catch {
    //                hanlder.handleOnError(context, error: error)
    //            }
    //}

    func onSuccess(_ event: OptistreamEvent) {
        if shouldPersist(event) {
            queue.remove(events: [event])
        }
    }

    func onError(_ event: OptistreamEvent) {
        if shouldPersist(event) {
            queue.enqueue(events: [event])
        }
    }

    func shouldPersist(_ event: OptistreamEvent) -> Bool {
        switch event.event {
        case OptimoveKeys.Configuration.setUserId.rawValue, OptimoveKeys.Configuration.setEmail.rawValue:
            return true
        default:
            return false
        }
    }

}

enum RealTimeError: LocalizedError {
    case eitherCustomerOrVisitorIdIsNil
    case deviceOffline

    var errorDescription: String? {
        switch self {
        case .eitherCustomerOrVisitorIdIsNil:
            return "Either a CustomerID or a VisitorID should not be nil."
        case .deviceOffline:
            return "Device is offline."
        }
    }
}

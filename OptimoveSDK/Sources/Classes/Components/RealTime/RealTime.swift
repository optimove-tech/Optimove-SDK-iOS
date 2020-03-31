//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class RealTime {

    struct Constatnts {
        static let timeThresholdInSeconds: TimeInterval = 1
        static let timeout: UInt32 = 1
    }

    private let configuration: RealtimeConfig
    private let realTimeQueue: DispatchQueue
    private let networking: RealTimeNetworking
    private let hanlder: RealTimeHanlder
    private var storage: OptimoveStorage
    private let eventBuilder: RealTimeEventBuilder
    private let coreEventFactory: CoreEventFactory
    private let semaphore = DispatchSemaphore(value: 1)

    // MARK: - Public

    required init(
        configuration: RealtimeConfig,
        storage: OptimoveStorage,
        networking: RealTimeNetworking,
        eventBuilder: RealTimeEventBuilder,
        handler: RealTimeHanlder,
        coreEventFactory: CoreEventFactory) {
        self.configuration = configuration
        self.storage = storage
        self.networking = networking
        self.realTimeQueue = DispatchQueue(label: "com.optimove.sdk.realtime", qos: .utility)
        self.hanlder = handler
        self.eventBuilder = eventBuilder
        self.coreEventFactory = coreEventFactory
        Logger.debug("RealTime initialized.")
    }

}

extension RealTime: Component {

    func handle(_ context: OperationContext) throws {
        guard isAllowedEvent(context) else { return }
        switch context.operation {
        case .setUserId:
            try reportUserId()
        case let .report(event: event):
            try reportEvent(event: event, retryFailedEvents: true)
        case let .reportScreenEvent(title: title, category: category):
            try coreEventFactory.createEvent(.pageVisit(title: title, category: category)) { event in
                tryCatch { try self.reportEvent(event: event) }
            }
        case .dispatchNow:
            // Consciously do nothing.
            break
        default:
            break
        }
    }
}

extension RealTime {

    func isAllowedEvent(_ context: OperationContext) -> Bool {
        let now = Date().timeIntervalSince1970
        return (now - context.timestamp) < Constatnts.timeThresholdInSeconds
    }

    func reportEvent(event: OptimoveEvent, retryFailedEvents: Bool = true) throws {
        let config = try event.matchConfiguration(with: configuration.events)
        guard config.supportedOnRealTime else {
            Logger.info("Realtime: Event \(event.name) is not supported.")
            return
        }
        do {
            let context = createEventContext(
                event: OptimoveEventDecorator(event: event, config: config),
                config: config
            )
            try report(context: context, retryFailedEvents: retryFailedEvents)
        } catch {
            Logger.error(error.localizedDescription)
        }
    }

    func reportUserId() throws {
        try coreEventFactory.createEvent(.setUserId) { event in
            tryCatch { try self.reportEvent(event: event, retryFailedEvents: false) }
        }
    }

    func reportUserEmail() throws {
        try coreEventFactory.createEvent(.setUserEmail) { event in
            tryCatch { try self.reportEvent(event: event, retryFailedEvents: false) }
        }
    }

}

// MARK: - Private

private extension RealTime {

    // MARK: Transforming an event

    func createEventContext(event: OptimoveEvent, config: EventsConfig) -> RealTimeEventContext {
        switch event.name {
        case OptimoveKeys.Configuration.setUserId.rawValue:
            return RealTimeEventContext(
                event: event,
                config: config,
                type: .setUserID
            )
        case OptimoveKeys.Configuration.setEmail.rawValue:
            return RealTimeEventContext(
                event: event,
                config: config,
                type: .setUserEmail
            )
        default:
            return RealTimeEventContext(
                event: event,
                config: config,
                type: .regular
            )
        }
    }

    // MARK: Prepare before send a report

    func report(context: RealTimeEventContext, retryFailedEvents: Bool) throws {
        if retryFailedEvents {
            try retryUserDataIfNeeded(context: context)
        }
        sentReportEvent(context: context)
    }

    // MARK: Retry

    /// Verify that failed set_user_id is dispatched before failed set_email
    /// and before any custom event.
    /// This is requirment from the Server-side.
    func retryUserDataIfNeeded(context: RealTimeEventContext) throws {
        // Do not invoke retry on a new UserID
        if context.type != .setUserID {
            try retrySetUserIdEventIfNeeded()
        }
        // Do not invoke retry on a new UserEmail
        if context.type != .setUserEmail {
            try retrySetUserEmailIfNeeded()
        }
    }

    func retrySetUserIdEventIfNeeded() throws {
        if storage.realtimeSetUserIdFailed {
            try reportUserId()
        }
    }

    func retrySetUserEmailIfNeeded() throws {
        if storage.realtimeSetEmailFailed {
            try reportUserEmail()
        }
    }

    // MARK: Send report

    func sentReportEvent(context: RealTimeEventContext) {
        let realtimeToken = configuration.realtimeToken

        realTimeQueue.async { [semaphore, eventBuilder, networking, hanlder] in
            do {
                /// The `semaphore.wait` added as the way to keep order in realtime events without possible race conditions produced by a network handling.
                semaphore.wait()
                let realtimeEvent = try eventBuilder.createEvent(context: context, realtimeToken: realtimeToken)
                try networking.report(event: realtimeEvent) { (result) in
                    semaphore.signal()
                    switch result {
                    case let .success(json):
                        hanlder.handleOnSuccess(context, json: json)
                    case let .failure(error):
                        hanlder.handleOnError(context, error: error)
                    }
                }
            } catch {
                hanlder.handleOnError(context, error: error)
            }
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

// Copiright 2019 Optimove

import Foundation

// Using for defining type of realtime event.
enum RealTimeEventType {
    case regular
    case setUserID
    case setUserEmail
}

protocol RealTimeEventContext {
    var event: OptimoveEvent { get }
    var config: EventsConfig { get }
    var type: RealTimeEventType { get }

    func onOffline()
    func onSuccess(_: String)
    func onError(_: Error)
    func onEncodeError(_: Error) // FIXME: Merge it with onError
}

struct RegularEventContext: RealTimeEventContext {
    private(set) var event: OptimoveEvent
    private(set) var config: EventsConfig
    private(set) var type: RealTimeEventType

    init(event: OptimoveEvent,
         config: EventsConfig) {
        self.event = event
        self.config = config
        self.type = .regular
    }

    func onOffline() {
        OptiLoggerMessages.logOfflineStatusForRealtime(eventName: event.name)
    }

    func onSuccess(_ json: String) {
        OptiLoggerMessages.logRealtimeReportStatus(json: json)
    }

    func onError(_ error: Error) {
        OptiLoggerMessages.logRealtimeRequestFailure(errorDescription: error.localizedDescription)
    }

    func onEncodeError(_: Error) {
        OptiLoggerMessages.logRealtimeSetUserIdEncodeFailure()
    }
}

struct SetUserIdEventContext: RealTimeEventContext {
    private(set) var event: OptimoveEvent
    private(set) var config: EventsConfig
    private(set) var type: RealTimeEventType

    init(event: OptimoveEvent,
         config: EventsConfig) {
        self.event = event
        self.config = config
        self.type = .setUserID
    }

    func onOffline() {
        OptiLoggerMessages.logSkipSetUserIdForRealtime()
    }

    func onSuccess(_ json: String) {
        OptiLoggerMessages.logRealtimeSetUserIdStatus(status: json)
    }

    func onError(_ error: Error) { }

    func onEncodeError(_: Error) {
        OptiLoggerMessages.logRealtimeSetUserIdEncodeFailure()
    }
}

struct SetUserEmailEventContext: RealTimeEventContext {
    private(set) var event: OptimoveEvent
    private(set) var config: EventsConfig
    private(set) var type: RealTimeEventType

    init(event: OptimoveEvent,
         config: EventsConfig) {
        self.event = event
        self.config = config
        self.type = .setUserEmail
    }

    func onOffline() {
        OptiLoggerMessages.logSkipSetEmailForRealtime()
    }

    func onSuccess(_ json: String) {
        OptiLoggerMessages.logRealtimeSetEmailStatus(status: json)
    }

    func onError(_ error: Error) { }

    func onEncodeError(_: Error) {
        OptiLoggerMessages.logRealtimeSetEmailEncodeFailure()
    }
}

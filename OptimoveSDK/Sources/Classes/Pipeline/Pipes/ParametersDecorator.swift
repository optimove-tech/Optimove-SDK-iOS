//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersDecorator: Pipe {
    private enum Constants {
        enum Key {
            static let eventDeviceType = "event_device_type"
            static let eventPlatform = "event_platform"
            static let eventOs = "event_os"
            static let eventNativeMobile = "event_native_mobile"
        }

        enum Value {
            static let eventDeviceType = "Mobile"
            static let eventPlatform = "iOS"
            static let eventOs = "iOS \(operatingSystemVersionOnlyString)"
            static let eventNativeMobile = true
            private static let operatingSystemVersionOnlyString = ProcessInfo().operatingSystemVersionOnlyString
        }
    }

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func deliver(_ operation: CommonOperation) throws {
        let decorationFunction = { [configuration] () -> CommonOperation in
            switch operation {
            case let .report(events: events):
                return ParametersDecorator.decoratedEvents(events, configuration)
            default:
                return operation
            }
        }
        try next?.deliver(decorationFunction())
    }

    private static func decoratedEvents(
        _ events: [Event],
        _ configuration: Configuration
    ) -> CommonOperation {
        let decoratedEvents: [Event] = events.map { event in
            guard let eventConfiguration = configuration.events[event.name] else {
                return event
            }
            event.isRealtime = eventConfiguration.supportedOnRealTime
            return ParametersDecorator.decorateWithDefaultParameters(
                event: event,
                eventConfig: eventConfiguration
            )
        }
        return CommonOperation.report(events: decoratedEvents)
    }

    private static func decorateWithDefaultParameters(
        event: Event,
        eventConfig: EventsConfig
    ) -> Event {
        let defaultParameters: [String: Any] = [
            Constants.Key.eventNativeMobile: Constants.Value.eventNativeMobile,
            Constants.Key.eventOs: Constants.Value.eventOs,
            Constants.Key.eventDeviceType: Constants.Value.eventDeviceType,
            Constants.Key.eventPlatform: Constants.Value.eventPlatform,
        ]
        defaultParameters
            .filter { defaultParameter -> Bool in
                eventConfig.parameters[defaultParameter.key] != nil
            }.forEach { defaultParameter in
                event.context[defaultParameter.key] = defaultParameter.value
            }
        return event
    }
}

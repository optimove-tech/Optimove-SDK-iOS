//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

extension Event {

    private struct Constants {
        struct Key {
            static let eventDeviceType = "event_device_type"
            static let eventPlatform = "event_platform"
            static let eventOs = "event_os"
            static let eventNativeMobile = "event_native_mobile"
        }
        struct Value {
            static let eventDeviceType = "Mobile"
            static let eventPlatform = "iOS"
            static let eventOs = "iOS \(operatingSystemVersionOnlyString)"
            static let eventNativeMobile = true
            private static let operatingSystemVersionOnlyString = ProcessInfo().operatingSystemVersionOnlyString

        }
    }

    func decorate(config: EventsConfig) -> Event {
        return Event(uuid: self.uuid,
                     name: self.name,
                     category: self.category,
                     context: decorate(config: config),
                     timestamp: self.timestamp,
                     isRealtime: config.supportedOnRealTime)
    }

    /// Add Additional attributes according to event configuration
    ///
    /// - Parameter config: The event configurations as provided in file
    private func decorate(config: EventsConfig) -> [String: Any] {
        var context = self.context
        if config.parameters[Constants.Key.eventDeviceType] != nil {
            context[Constants.Key.eventDeviceType] = Constants.Value.eventDeviceType
        }
        if config.parameters[Constants.Key.eventNativeMobile] != nil {
            context[Constants.Key.eventNativeMobile] = Constants.Value.eventNativeMobile
        }
        if config.parameters[Constants.Key.eventOs] != nil {
            context[Constants.Key.eventOs] = Constants.Value.eventOs
        }
        if config.parameters[Constants.Key.eventPlatform] != nil {
            context[Constants.Key.eventPlatform] = Constants.Value.eventPlatform
        }
        return context
    }

}

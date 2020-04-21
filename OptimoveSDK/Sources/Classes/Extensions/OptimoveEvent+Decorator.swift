//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

extension Event {

    private struct Constants {
        struct Key {
            static let eventDeviceType = OptimoveKeys.AdditionalAttributesKeys.eventDeviceType
            static let eventNativeMobile = OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile
            static let eventOs = OptimoveKeys.AdditionalAttributesKeys.eventOs
            static let eventPlatform = OptimoveKeys.AdditionalAttributesKeys.eventPlatform
        }
        struct Value {
            static let eventDeviceType = OptimoveKeys.AddtionalAttributesValues.eventDeviceType
            static let eventNativeMobile = OptimoveKeys.AddtionalAttributesValues.eventNativeMobile
            static let eventOs = OptimoveKeys.AddtionalAttributesValues.eventOs
            static let eventPlatform = OptimoveKeys.AddtionalAttributesValues.eventPlatform
        }
    }

    func decorate(config: EventsConfig) -> Event {
        return Event(uuid: self.uuid,
                     name: self.name,
                     category: self.category,
                     context: decorate(config: config),
                     timestamp: self.timestamp)
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

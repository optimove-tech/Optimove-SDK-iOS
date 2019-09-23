//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Adjust event entity to satisfy Optimove's business logic before dispatch
final class OptimoveEventDecorator: OptimoveEvent {

    struct Constants {
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

    var name: String
    var parameters: [String: Any]

    init(event: OptimoveEvent) {
        self.name = event.name
        self.parameters = event.parameters
    }

    /// For core events, where the naming conventions is satisfy by the event source, use this convenience initializer to just add the additional attributes according to the config file.
    ///
    /// - Parameters:
    ///   - event: Event that is sent to Track & Trigger
    ///   - config: The config of the event as provided by the config file
    convenience init(event: OptimoveEvent, config: EventsConfig) {
        self.init(event: event)
        self.decorate(config)
    }

    /// Add Additional attributes according to event configuration
    ///
    /// - Parameter config: The event configurations as provided in file
    func decorate(_ config: EventsConfig) {
        if config.parameters[Constants.Key.eventDeviceType] != nil {
            self.parameters[Constants.Key.eventDeviceType] = Constants.Value.eventDeviceType
        }
        if config.parameters[Constants.Key.eventNativeMobile] != nil {
            self.parameters[Constants.Key.eventNativeMobile] = Constants.Value.eventNativeMobile
        }
        if config.parameters[Constants.Key.eventOs] != nil {
            self.parameters[Constants.Key.eventOs] = Constants.Value.eventOs
        }
        if config.parameters[Constants.Key.eventPlatform] != nil {
            self.parameters[Constants.Key.eventPlatform] = Constants.Value.eventPlatform
        }
    }

}

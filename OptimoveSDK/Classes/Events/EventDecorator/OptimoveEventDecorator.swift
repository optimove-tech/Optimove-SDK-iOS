import Foundation

/// Adjust event entity to satisfy Optimove's business logic before dispatch
class OptimoveEventDecorator: OptimoveEvent {
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
        self.processEventConfig(config)
    }

    /// Add Additional attributes according to event configuration
    ///
    /// - Parameter config: The event configurations as provided in file
    func processEventConfig(_ config: EventsConfig) {
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventDeviceType] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventDeviceType]
                = OptimoveKeys.AddtionalAttributesValues.eventDeviceType
        }
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile]
                = OptimoveKeys.AddtionalAttributesValues.eventNativeMobile
        }
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventOs] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventOs]
                = OptimoveKeys.AddtionalAttributesValues.eventOs
        }
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventPlatform] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventPlatform]
                = OptimoveKeys.AddtionalAttributesValues.eventPlatform
        }

        normalizeParameters(config)
    }

    /// For core events, where the naming conventions is satisfy by the event source, just normalize the parameter type if necessary
    ///
    /// - Parameter config: The configuration of the event as provided from the config file
    func normalizeParameters(_ config: EventsConfig) {
        var normalizedParameters = [String: Any]()
        for (key, value) in parameters {
            if let numValue = value as? NSNumber, config.parameters[key]?.type == "Boolean" {
                normalizedParameters[key] = Bool(truncating: numValue)
            } else if let strValue = value as? String {
                normalizedParameters[key] = strValue.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                normalizedParameters[key] = value
            }
        }
        self.parameters = normalizedParameters
    }
}

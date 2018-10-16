
import Foundation

/// Adjust event entity to satisfy Optimove's business logic before dispatch
class OptimoveEventDecorator:OptimoveEvent
{
    var name: String
    var parameters: [String : Any]
    let isOptimoveCoreEvent:Bool

    /// For custom events, where the source might not apply to Optimove's naming conventions, use this designated initializer to first apply normalization rules. Then, with the normalized event wrapped in the decorator, you can fetch the event's configs from the configuration file and call the processEventConfig(_) method.
    /// - Parameter event: Event that is sent to Track & Trigger
    init(event:OptimoveEvent)
    {
        self.name = event.name
        self.parameters = event.parameters
        self.isOptimoveCoreEvent = event is OptimoveCoreEvent

        if !isOptimoveCoreEvent {
            name = name.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
            parameters = normalize(parameters: parameters)
        }
    }

    /// For core events, where the naming conventions is satisfy by the event source, use this convenience initializer to just add the additional attributes according to the config file.
    ///
    /// - Parameters:
    ///   - event: Event that is sent to Track & Trigger
    ///   - config: The config of the event as provided by the config file
    convenience init(event:OptimoveEvent,config:OptimoveEventConfig)
    {
        self.init(event: event)
        self.processEventConfig(config)
    }

    /// Add Additional attributes according to event configuration
    ///
    /// - Parameter config: The event configurations as provided in file
    func processEventConfig(_ config:OptimoveEventConfig)
    {
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventDeviceType] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventDeviceType] = OptimoveKeys.AddtionalAttributesValues.eventDeviceType
        }
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile] = OptimoveKeys.AddtionalAttributesValues.eventNativeMobile
        }
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventOs] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventOs] = OptimoveKeys.AddtionalAttributesValues.eventOs
        }
        if config.parameters[OptimoveKeys.AdditionalAttributesKeys.eventPlatform] != nil {
            self.parameters[OptimoveKeys.AdditionalAttributesKeys.eventPlatform] = OptimoveKeys.AddtionalAttributesValues.eventPlatform
        }
    }

    /// Normalize all event parameters to fulfill Optimove settings
    ///
    /// - Parameter parameters: The original parameters as provided by the client
    /// - Returns: The mutated parameters
    private func normalize(parameters: [String:Any]) -> [String:Any]
    {
        var normalizeParams = parameters
        for key in parameters.keys {
            normalizeParams[key.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")] = parameters[key]
        }
        return normalizeParams
    }
}


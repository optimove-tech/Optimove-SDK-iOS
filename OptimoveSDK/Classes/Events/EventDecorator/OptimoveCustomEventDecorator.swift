//
//  OptimoveCustomEventDecorator.swift
//  OptimoveSDK

import Foundation

final class OptimoveCustomEventDecorator: OptimoveEventDecorator {

    /// For custom events, where the source might not apply to Optimove's naming conventions, use this designated initializer to first apply normalization rules. Then, with the normalized event wrapped in the decorator, you can fetch the event's configs from the configuration file and call the processEventConfig(_) method.
    /// - Parameter event: Event that is sent to Track & Trigger
    override init(event: OptimoveEvent) {
        super.init(event: event)
        name = normalize(event.name)
    }

    /// For custom events, where the source might not apply to Optimove's naming conventions, normalize the parameter keys to align with optimove configurations
    ///
    /// - Parameter config:  The configuration of the event as provided from the config file
    override func normalizeParameters(_ config: EventsConfig) {
        var normalizedParameters = [String: Any]()
        for (key, value) in parameters {
            let normalizedKey = normalize(key)
            if let numValue = value as? NSNumber, config.parameters[normalizedKey]?.type == ConfigurationType.boolean {
                normalizedParameters[normalizedKey] = Bool(truncating: numValue)
            } else {
                normalizedParameters[normalizedKey] = value
            }
            if normalizedKey != key {
                normalizedParameters[key] = nil
            }
        }
        self.parameters = normalizedParameters
    }

    /// Adapt string to fulfill Optimove settings for any event parameter's key
    ///
    /// - Parameter string: The original parameters as provided by the client
    /// - Returns: The mutated parameters

    func normalize(_ string: String) -> String {
        return string.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
    }

    private struct ConfigurationType {
        static let boolean = "Boolean"
    }
}

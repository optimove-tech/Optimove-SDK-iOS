//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersNormalizer: Pipe {
    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - EventableHandler

    override func deliver(_ operation: CommonOperation) throws {
        let normilizeFunction = { () -> CommonOperation in
            switch operation {
            case let .report(events: events):
                return try CommonOperation.report(
                    events: self.normilize(events)
                )
            default:
                return operation
            }
        }
        try next?.deliver(normilizeFunction())
    }

    private func normilize(_ events: [Event]) throws -> [Event] {
        return try events.map { event in
            if event.category == TenantEvent.Constants.category {
                return try event.normilize(configuration.events)
            }
            return event
        }
    }
}

extension Event {
    private enum Constants {
        static let boolean = "Boolean"
    }

    /// The normalization process contains next steps:
    /// - Replacing all spaces in a key with underscore character.
    /// - Handling Boolean type correctly.
    /// - Clean up an value of an non-normilized key.
    ///
    /// - Parameter event: The event for normilization.
    /// - Returns: Normilized event
    /// - Throws: Throw an error if an event configuration are missing.
    func normilize(_ events: [String: EventsConfig]) throws -> Event {
        let normilizeName = name.normilizeKey()
        guard let eventConfig = events[normilizeName] else {
            return self
        }
        let normalizedParameters = context.reduce(into: [String: Any]()) { result, next in
            // Replacing all spaces in a key with underscore character.
            let normalizedKey = next.key.normilizeKey()

            // Handling Boolean type correctly.
            if let number = next.value as? NSNumber, eventConfig.parameters[normalizedKey]?.type == Constants.boolean {
                result[normalizedKey] = Bool(truncating: number)
            } else if let string = next.value as? String {
                result[normalizedKey] = string.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                result[normalizedKey] = next.value
            }

            // Clean up an value of an non-normilized key.
            if normalizedKey != next.key {
                result[next.key] = nil
            }
        }
        return Event(
            eventId: eventId,
            name: normilizeName,
            category: category,
            context: normalizedParameters,
            timestamp: timestamp
        )
    }
}

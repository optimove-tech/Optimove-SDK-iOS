//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersNormalizer: Node {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - EventableHandler

    override func execute(_ operation: Operation) throws {
        let normilizeFunction = { [configuration] () -> Operation in
            switch operation {
            case let .report(event: event) where event.category == TenantEvent.Constants.category:
                return Operation.report(
                    event: try event.normilize(configuration.events)
                )
            default:
                return operation
            }
        }
        try next?.execute(normilizeFunction())
    }

}

extension Event {

    private struct Constants {
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
        let normilizeName = self.name.normilizeKey()
        guard let eventConfig = events[normilizeName] else {
            throw GuardError.custom("Configurations are missing for event \(self.name)")
        }
        let normalizedParameters = self.context.reduce(into: [String: Any]()) { (result, next) in
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
            uuid:self.uuid,
            name: normilizeName,
            category: self.category,
            context: normalizedParameters,
            timestamp: self.timestamp
        )
    }

}

private extension String {

    private struct Constants {
        static let spaceCharacter = " "
        static let underscoreCharacter = "_"
    }

    func normilizeKey(with replacement: String = Constants.underscoreCharacter) -> String {
        return self.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: Constants.spaceCharacter, with: replacement)
    }
}


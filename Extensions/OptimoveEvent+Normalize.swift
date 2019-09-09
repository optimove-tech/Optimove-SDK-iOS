//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

private struct Constants {
    static let boolean = "Boolean"
}

extension OptimoveEvent {

    /// The normalization process contains next steps:
    /// - Replacing all spaces in a key with underscore character.
    /// - Handling Boolean type correctly.
    /// - Clean up an value of an non-normilized key.
    ///
    /// - Parameter event: The event for normilization.
    /// - Returns: Normilized event
    /// - Throws: Throw an error if an event configuration are missing.
    func normilize(_ events: [String: EventsConfig]) throws -> OptimoveEvent {
        guard let eventConfig = events[self.name] else {
            throw GuardError.custom("Configurations are missing for event \(self.name)")
        }
        let normalizedParameters = self.parameters.reduce(into: [String: Any]()) { (result, next) in
            // Replacing all spaces in a key with underscore character.
            let normalizedKey = next.key.replaceSpaces()

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
        return CommonOptimoveEvent(name: self.name, parameters: normalizedParameters)
    }

}

private extension String {

    private struct Constants {
        static let spaceCharacter = " "
        static let underscoreCharacter = "_"
    }

    func replaceSpaces(with replacement: String = Constants.underscoreCharacter) -> String {
        return self.lowercased()
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: Constants.spaceCharacter, with: replacement)
    }
}

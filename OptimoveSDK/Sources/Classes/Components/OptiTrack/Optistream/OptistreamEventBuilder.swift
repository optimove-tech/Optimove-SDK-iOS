//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore

/// Builds an Optistream event from internal event type.
final class OptistreamEventBuilder {

    private struct Constants {
        static let origin = "sdk"
    }

    private let configuration: OptitrackConfig
    private let storage: OptimoveStorage

    init(configuration: OptitrackConfig,
         storage: OptimoveStorage) {
        self.configuration = configuration
        self.storage = storage
    }

    func build(
        event: Event,
        timestamp: TimeInterval,
        category: String) throws -> OptistreamEvent {
        return OptistreamEvent(
            tenant: configuration.tenantID,
            category: category,
            event: event.name,
            origin: Constants.origin,
            customer: storage.customerID,
            visitor: try storage.getVisitorID(),
            timestamp: timestamp,
            context: event.parameters
        )
    }

}

typealias EventParameters = [String: JsonType]

protocol Event {
    var name: String { get }
    var parameters: EventParameters { get }
}

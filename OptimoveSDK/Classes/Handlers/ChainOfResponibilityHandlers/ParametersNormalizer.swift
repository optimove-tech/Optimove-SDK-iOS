//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersNormalizer: EventableNode {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - EventableHandler

    override func execute(_ context: EventableOperationContext) throws {
        let normilizeFunction = { [configuration] () -> EventableOperationContext in
            switch context.operation {
            case let .report(event: event):
                return EventableOperationContext(
                    .report(event:
                        try event.normilize(configuration.events)
                    ),
                    timestamp: context.timestamp
                )
            default:
                return context
            }
        }
        try next?.execute(normilizeFunction())
    }

}


//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersNormalizer: EventableHandler {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - EventableHandler

    override func handle(_ context: EventableOperationContext) throws {
        let normilizeFunction = { [configuration] () -> EventableOperationContext in
            switch context.operation {
            case let .report(event: event):
                return EventableOperationContext(
                    .report(event:
                        try event.normilize(configuration.events)
                    ),
                    isBuffered: context.isBuffered
                )
            default:
                return context
            }
        }
        try next?.handle(normilizeFunction())
    }

}


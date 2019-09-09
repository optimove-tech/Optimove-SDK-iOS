//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersDecorator: EventableHandler {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func handle(_ context: EventableOperationContext) throws {
        let decorationFunction = { [configuration] () -> EventableOperationContext in
            switch context.operation {
            case let .report(event: event):
                let pair = try event.matchConfiguration(with: configuration.events)
                return EventableOperationContext(
                    .report(event:
                        OptimoveEventDecorator(event: pair.event, config: pair.config)
                    )
                )
            default:
                return context
            }
        }
        try next?.handle(decorationFunction())
    }

}

//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersNormalizer: Node {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - EventableHandler

    override func execute(_ context: OperationContext) throws {
        let normilizeFunction = { [configuration] () -> OperationContext in
            switch context.operation {
            case let .eventable(eventableOperation):
                switch eventableOperation {
                case let .report(event: event):
                    return OperationContext(
                        operation: .eventable(
                            .report(event:
                                try event.normilize(configuration.events)
                            )
                        ),
                        timestamp: context.timestamp
                    )
                default:
                    return context
                }
            default:
                return context
            }
        }
        try next?.execute(normilizeFunction())
    }

}


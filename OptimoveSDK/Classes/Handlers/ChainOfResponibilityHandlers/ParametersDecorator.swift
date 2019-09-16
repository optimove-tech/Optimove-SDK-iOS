//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersDecorator: Node {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func execute(_ context: OperationContext) throws {
        let decorationFunction = { [configuration] () -> OperationContext in
            switch context.operation {
            case let .eventable(eventableOperation):
                switch eventableOperation {
                case let .report(event: event):
                    return OperationContext(
                        operation: .eventable(
                            .report(event:
                                OptimoveEventDecorator(
                                    event: event,
                                    config: try event.matchConfiguration(with: configuration.events)
                                )
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
        try next?.execute(decorationFunction())
    }

}

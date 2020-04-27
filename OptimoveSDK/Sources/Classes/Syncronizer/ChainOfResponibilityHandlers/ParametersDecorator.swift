//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersDecorator: Node {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func execute(_ operation: Operation) throws {
        let decorationFunction = { [configuration] () -> Operation in
            switch operation {
            case let .report(event: event):
                return Operation.report(
                    event: event.decorate(
                        config: try event.matchConfiguration(with: configuration.events)
                    )
                )
            default:
                return operation
            }
        }
        try next?.execute(decorationFunction())
    }

}

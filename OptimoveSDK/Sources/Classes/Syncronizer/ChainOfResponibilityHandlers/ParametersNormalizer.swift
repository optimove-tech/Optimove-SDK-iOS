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
            case let .report(event: event):
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

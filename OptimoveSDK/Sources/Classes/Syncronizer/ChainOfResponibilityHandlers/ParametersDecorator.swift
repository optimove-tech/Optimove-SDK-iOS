//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class ParametersDecorator: Node {

    private let configuration: Configuration

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    override func execute(_ operation: CommonOperation) throws {
        let decorationFunction = { [configuration] () -> CommonOperation in
            switch operation {
            case let .report(events: events):
                return CommonOperation.report(
                    events: events.map { event in
                        if let configuration = configuration.events[event.name] {
                            return event.decorate(config: configuration)
                        }
                        return event
                    }
                )
            default:
                return operation
            }
        }
        try next?.execute(decorationFunction())
    }

}

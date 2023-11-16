//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

class ComponentHandler: Pipe {
    private let commonComponents: [CommonComponent]
    private let optistreamComponents: [OptistreamComponent]
    private let optirstreamEventBuilder: OptistreamEventBuilder

    init(commonComponents: [CommonComponent],
         optistreamComponents: [OptistreamComponent],
         optirstreamEventBuilder: OptistreamEventBuilder)
    {
        self.commonComponents = commonComponents
        self.optistreamComponents = optistreamComponents
        self.optirstreamEventBuilder = optirstreamEventBuilder
    }

    override func deliver(_ operation: CommonOperation) throws {
        sendToCommonComponents(operation)
        sendToStreamComponents(operation)
    }

    private func sendToCommonComponents(_ operation: CommonOperation) {
        commonComponents.forEach { component in
            tryCatch {
                try component.serve(operation)
            }
        }
    }

    private func sendToStreamComponents(_ operation: CommonOperation) {
        switch operation {
        case let .report(events: events):
            let streamEvents: [OptistreamEvent] = events.compactMap { event in
                do {
                    return try optirstreamEventBuilder.build(event: event)
                } catch {
                    Logger.error(error.localizedDescription)
                    return nil
                }
            }
            optistreamComponents.forEach { component in
                tryCatch {
                    try component.serve(.report(events: streamEvents))
                }
            }
        case .dispatchNow:
            optistreamComponents.forEach { component in
                tryCatch {
                    try component.serve(.dispatchNow)
                }
            }
        default:
            break
        }
    }
}

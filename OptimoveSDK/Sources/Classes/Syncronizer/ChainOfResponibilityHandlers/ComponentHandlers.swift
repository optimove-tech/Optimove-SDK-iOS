//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

class ComponentHandler: Node {
    private let components: [Component]

    init(components: [Component]) {
        self.components = components
    }

    override func execute(_ context: Operation) throws {
        components.forEach { component in
            do {
                try component.handle(context)
            } catch {
                Logger.error(error.localizedDescription)
            }
        }
    }

}

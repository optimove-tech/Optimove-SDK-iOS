//  Copyright © 2019 Optimove. All rights reserved.

@testable import OptimoveCore

final class StubEvent: Event {

    struct Constnats {
        static let id = 2_000
        static let name = "stub_name"
        static let key = "stub_key"
        static let value = "stub_value"
    }

    init() {
        super.init(name: Constnats.name, context: [
            Constnats.key: Constnats.value
        ])
    }

}

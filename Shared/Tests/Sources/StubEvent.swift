//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

final class StubEvent: Event {

    struct Constnats {
        static let id = 2_000
        static let name = "stub_name"
        static let key = "stub_key"
        static let value = "stub_value"
    }

    init() {
        super.init(name: Constnats.name, context: [:])
    }

    init(context: [String: Any]) {
        super.init(name: Constnats.name, context: context)
    }

}

public let StubOptistreamEvent = OptistreamEvent(
    tenant: StubVariables.tenantID,
    category: "test",
    event: "stub",
    origin: "sdk",
    customer: nil,
    visitor: StubVariables.initialVisitorId,
    timestamp: Formatter.iso8601withFractionalSeconds.string(from: Date()),
    context: [],
    metadata: OptistreamEvent.Metadata(
        realtime: true,
        firstVisitorDate: Date().timeIntervalSince1970.seconds,
        eventId: UUID().uuidString,
        requestId: UUID().uuidString
    )
)

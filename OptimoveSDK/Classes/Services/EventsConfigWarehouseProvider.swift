//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

final class EventsConfigWarehouseProvider {

    private var warehouse: EventsConfigWarehouse?

    func getWarehouse() throws -> EventsConfigWarehouse {
        guard let warehouse = warehouse else {
            throw Error.noWarehouse
        }
        return warehouse
    }

    func setWarehouse(_ warehouse: EventsConfigWarehouse) {
        self.warehouse = warehouse
    }

    enum Error: LocalizedError {
        case noWarehouse

        var errorDescription: String? {
            switch self {
            case .noWarehouse:
                return "Unable provide a warehouse."
            }
        }
    }

}

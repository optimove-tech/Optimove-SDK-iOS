// Copiright 2019 Optimove

import OptimoveCore
@testable import OptimoveSDK

final class StubOptimoveEventConfigsWarehouse: EventsConfigWarehouse {

    var config: EventsConfig = EventsConfig(
        id: Int(Int16.max),
        supportedOnOptitrack: true,
        supportedOnRealTime: true,
        parameters: [:]
    )

    func getConfig(for event: OptimoveEvent) -> EventsConfig? {
        return config
    }

    func addParameters(_ newParameters: [String: Parameter]) {
        var parameters = config.parameters
        newParameters.forEach { (parameter) in
            parameters.updateValue(parameter.value, forKey: parameter.key)
        }
        config = EventsConfig(
            id: config.id,
            supportedOnOptitrack: config.supportedOnOptitrack,
            supportedOnRealTime: config.supportedOnRealTime,
            parameters: parameters
        )
    }
}

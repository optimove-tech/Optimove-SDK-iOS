//  Copyright © 2020 Optimove. All rights reserved.

import CoreLocation
import Foundation
@testable import OptimoveSDK

final class MockLocationService: LocationService {
    func useLocationManager(_: CLLocationManager) {}

    func getLocation(onComplete: @escaping (Result<[Location: String], LocationError>) -> Void) {
        onComplete(.success([
            .latitude: "51.507222",
            .longitude: "-0.1275",
            .locality: "london",
        ]))
    }
}

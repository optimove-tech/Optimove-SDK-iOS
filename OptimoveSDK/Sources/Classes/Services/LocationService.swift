//  Copyright © 2020 Optimove. All rights reserved.

import Foundation
import OptimoveCore
import CoreLocation

enum Location: String {
    case latitude
    case longitude
    case locality
}

enum LocationError: String, Error {
    case notAuthorized
    case noLocation
    case noLocality
}

protocol LocationService {
    func getLocation(onComplete: @escaping (Result<[Location: String], LocationError>) -> Void)
}

extension LocationServiceImpl: LocationService {

    func getLocation(onComplete: @escaping (Result<[Location: String], LocationError>) -> Void) {
        if isMainAppHasLocationDescriptions(), isLocationAuthorized() {
            return getCoordinates(onComplete)
        }
        onComplete(.failure(.notAuthorized))
    }

}

final class LocationServiceImpl {

    private func isMainAppHasLocationDescriptions() -> Bool {
        return (Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription") != nil) ||
        (Bundle.main.object(forInfoDictionaryKey: "NSLocationAlwaysUsageDescription") != nil)
    }

    private func isLocationAuthorized() -> Bool {
        return CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse
    }

    private func getCoordinates(_ onComplete: @escaping (Result<[Location: String], LocationError>) -> Void) {
        let manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        guard let location = CLLocationManager().location else {
            onComplete(.failure(.noLocation))
            return
        }
        var locations: [Location: String] = [
            .latitude: String(location.coordinate.latitude),
            .longitude: String(location.coordinate.longitude)
        ]
        getLocality(location: location) { (result) in
            switch result {
            case let .success(locality):
                locations[.locality] = locality
            case let .failure(error):
                Logger.error(error.localizedDescription)
            }
            onComplete(.success(locations))
        }
    }

    private func getLocality(location: CLLocation,
                             onComplete: @escaping (Result<String, LocationError>) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            guard let locality = placemarks?.filter({ $0.locality != nil }).first?.locality else {
                onComplete(.failure(.noLocality))
                return
            }
            onComplete(.success(locality))
        }
    }

}

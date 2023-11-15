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
        DispatchQueue.main.async {
            if self.isAuthorized(), self.hasDescriptions {
                return self.getCoordinates(onComplete)
            }
            onComplete(.failure(.notAuthorized))
        }
    }

}

final class LocationServiceImpl {

    private let locationManager = CLLocationManager()
    private let preferredLocale = Locale(identifier: "en_US_POSIX")
    private let descriptionKeys: [String] = [
        "NSLocationAlwaysUsageDescription",
        "NSLocationWhenInUseUsageDescription"
    ]
    private let authorizedStatuses: [CLAuthorizationStatus] = [
        .authorizedAlways,
        .authorizedWhenInUse
    ]
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyKilometer
    private var hasDescriptions = false

    init() {
        hasDescriptions = self.hasDescriptionForMainApp()
    }

    private func hasDescriptionForMainApp() -> Bool {
        return !descriptionKeys.compactMap(Bundle.main.object).isEmpty
    }

    private func isAuthorized() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        return authorizedStatuses.contains(status)
    }

    private func getCoordinates(_ onComplete: @escaping (Result<[Location: String], LocationError>) -> Void) {
        locationManager.desiredAccuracy = desiredAccuracy
        guard let location = locationManager.location else {
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
        let completionHandler: CLGeocodeCompletionHandler = { (placemarks, error) in
            if let error = error {
                Logger.error(error.localizedDescription)
                onComplete(.failure(.noLocality))
                return
            }
            func findLocality() -> String? {
                return placemarks?.filter { $0.locality != nil }.first?.locality
            }
            switch findLocality() {
            case Optional.none:
                onComplete(.failure(.noLocality))
            case Optional.some(let locality):
                onComplete(.success(locality))
            }
        }
        if #available(iOS 11, *) {
            CLGeocoder().reverseGeocodeLocation(
                location,
                preferredLocale: preferredLocale,
                completionHandler: completionHandler
            )
        } else {
            CLGeocoder().reverseGeocodeLocation(
                location,
                completionHandler: completionHandler
            )
        }
    }

}

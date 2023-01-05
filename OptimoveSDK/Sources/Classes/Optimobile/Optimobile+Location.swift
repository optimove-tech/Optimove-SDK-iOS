

import Foundation
import CoreLocation

extension Optimobile {
    static func sendLocationUpdate(location: CLLocation) {
        let parameters = [
            "lat" : location.coordinate.latitude,
            "lng" : location.coordinate.longitude
        ]

        Optimobile.trackEvent(eventType: OptimobileEvent.ENGAGE_LOCATION_UPDATED, properties: parameters, immediateFlush: true)
    }
    
    static func trackIBeaconProximity(beacon: CLBeacon) {
        let parameters = [
            "type": 1,
            "uuid": beacon.proximityUUID.uuidString,
            "major": beacon.major.stringValue,
            "minor": beacon.minor.stringValue,
            "proximity" : beacon.proximity.rawValue
        ] as [String : Any];
        
        Optimobile.trackEvent(eventType: OptimobileEvent.ENGAGE_BEACON_ENTERED_PROXIMITY, properties: parameters, immediateFlush: true)
    }
    
    static func trackEddystoneBeaconProximity(hexNamespace: String, hexInstance:String, distanceMeters:Double?) {
        var parameters = [
            "type": 2,
            "namespace": hexNamespace,
            "instance": hexInstance
        ] as [String : Any];
        
        if (distanceMeters != nil){
            parameters["distance"] = distanceMeters
        }
        
        Optimobile.trackEvent(eventType: OptimobileEvent.ENGAGE_BEACON_ENTERED_PROXIMITY, properties: parameters, immediateFlush: true)
    }
}

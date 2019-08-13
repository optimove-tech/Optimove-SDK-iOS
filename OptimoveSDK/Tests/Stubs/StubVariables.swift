// Copiright 2019 Optimove

import Foundation
@testable import OptimoveSDK

struct StubVariables {

    static let int = 42
    static let string = "string"
    static let bool = true
    static let url = URL(string: "http://173.255.119.3/")!

    static let coreParameters: [Int: String] = [
        12: OptimoveKeys.AdditionalAttributesKeys.eventPlatform,
        13: OptimoveKeys.AdditionalAttributesKeys.eventDeviceType,
        14: OptimoveKeys.AdditionalAttributesKeys.eventOs,
        15: OptimoveKeys.AdditionalAttributesKeys.eventNativeMobile,
    ]

    // MARK: - Strorage

    static let visitorID = "visitorID".lowercased()
    static let customerID = "customerID".lowercased()
    static let userEmail = "userEmail".lowercased()
    static let initialVisitorId = "initialVisitorId".lowercased()
}

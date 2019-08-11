//
//  OptipushMetaData.swift
//  OptimoveSDK
//
//  Created by Mobile Developer Optimove on 05/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct OptipushMetaData: Codable, MetaData {
    let registrationServiceRegistrationEndPoint: URL
    let registrationServiceOtherEndPoint: URL
    let pushTopicsRegistrationEndpoint: URL
    let enableAdvertisingIdReport: Bool?

    enum CodingKeys: String, CodingKey {
        case enableAdvertisingIdReport
        case pushTopicsRegistrationEndpoint
        case registrationServiceRegistrationEndPoint = "onlyRegistrationServiceEndpoint"
        case registrationServiceOtherEndPoint = "otherRegistrationServiceEndpoint"
    }
}

//
//  OptimoveEvent.swift
//  iOS-SDK
//
//  Created by Mobile Developer Optimove on 04/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

struct OptimoveEventConfig: Decodable {
    let id: Int
    let supportedOnOptitrack: Bool
    let supportedOnRealTime: Bool
    let parameters: [String: Parameter]
}

//
//  Event.swift
//  OptimoveSDKDev
//
//  Created by Mobile Developer Optimove on 06/09/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

@objc public protocol OptimoveEvent {
    @objc var name: String { get }
    @objc var parameters: [String: Any] { get }
}

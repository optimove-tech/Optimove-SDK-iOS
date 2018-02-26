//
//  OptimoveError.swift
//  OptimoveSDK
//
//  Created by Elkana Orbach on 28/12/2017.
//  Copyright © 2017 Optimove. All rights reserved.
//

import Foundation

@objc public enum OptimoveError:Int
{
    case noError = 0
    case error
    case optipushServerNotAvailable
    case optipushComponentUnavailable
    case optiTrackComponentUnavailable
    case noNetwork
    case noPermissions
    case invalidEvent
    case mandatoryParameterMissing
    case cantStoreFileInLocalStorage
    case canNotParseData
    case emptyData
}

//
//  OptimoveDeepLinkResponding.swift
//  OptimoveSDK

import Foundation
@objc protocol OptimoveDeepLinkResponding {
    @objc func register(deepLinkResponder responder: OptimoveDeepLinkResponder)
    @objc func unregister(deepLinkResponder responder: OptimoveDeepLinkResponder)
}

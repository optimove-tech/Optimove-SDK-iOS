//
//  SdkVersionEvent.swift
//  OptimoveSDK


import Foundation

class SdkVersionEvent:OptimoveCoreEvent {
    var name: String
    var parameters: [String : Any]

    init(configUrl:String) {
        self.name = "optimove_sdk_metadata"
        self.parameters  = ["sdk_version": "2.0.0",
                            "config_file_url": configUrl,
                            "sdk_platform": "iOS",
        "app_ns":Bundle.main.bundleIdentifier!]
    }


}

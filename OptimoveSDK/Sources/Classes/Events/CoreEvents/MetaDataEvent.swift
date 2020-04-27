//  Copyright © 2019 Optimove. All rights reserved.

final class MetaDataEvent: Event {

    struct Constants {
        static let name = "optimove_sdk_metadata"
        static let sdkPlatform = "iOS"
        struct Key {
            static let sdkVersion = "sdk_version"
            static let configFileURL = "config_file_url"
            static let sdkPlatform = "sdk_platform"
            static let appNS = "app_ns"
            static let location = "location"
            static let locationLatitude = "location_latitude"
            static let locationLongitude = "location_longitude"
            static let language = "language"
        }
    }

    init(configUrl: String,
         sdkVersion: String,
         bundleIdentifier: String,
         location: String?,
         locationLatitude: String?,
         locationLongitude: String?,
         language: String?) {
        let params: [String: Any?] = [
            Constants.Key.sdkVersion: sdkVersion,
            Constants.Key.configFileURL: configUrl,
            Constants.Key.sdkPlatform: Constants.sdkPlatform,
            Constants.Key.appNS: bundleIdentifier,
            Constants.Key.location: location,
            Constants.Key.locationLatitude: locationLatitude,
            Constants.Key.locationLongitude: locationLongitude,
            Constants.Key.language: language
        ]
        super.init(name: Constants.name, context: params.filter { $0.value != nil } as [String: Any])
    }

}

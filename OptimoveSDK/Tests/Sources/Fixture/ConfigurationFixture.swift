//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

final class ConfigurationFixture: FileAccessible {

    let fileName: String = "core_events.json"
    private var events: [String: EventsConfig] = [:]

    init() {
        events = createEventFixture()
    }

    func configurationFixture() -> Configuration {
        return Configuration(
                tenantID: StubVariables.int,
                logger: loggerConfigFixture(),
                realtime: realtimeConfigFixture(),
                optitrack: optitrackConfigFixture(),
                optipush: optipushConfigFixture(),
                events: eventsFuxture()
        )
    }

    func realtimeConfigFixture() -> RealtimeConfig {
        return RealtimeConfig(
            tenantID: StubVariables.int,
            realtimeToken: StubVariables.string,
            realtimeGateway: StubVariables.url,
            events: eventsFuxture()
        )
    }

    func optitrackConfigFixture() -> OptitrackConfig {
        return OptitrackConfig(
            tenantID: StubVariables.int,
            optitrackEndpoint: StubVariables.url,
            enableAdvertisingIdReport: StubVariables.bool,
            eventCategoryName: StubVariables.string,
            customDimensionIDS: customDimensionIDsFixture(),
            events: eventsFuxture()
        )
    }

    func optipushConfigFixture() -> OptipushConfig {
        return OptipushConfig(
            tenantID: StubVariables.int,
            registrationServiceEndpoint: StubVariables.url,
            pushTopicsRegistrationEndpoint: StubVariables.url,
            firebaseProjectKeys: firebaseProjectKeysFixture(),
            clientsServiceProjectKeys: clientsServiceProjectKeysFixture()
        )
    }

}

private extension ConfigurationFixture {

    func createEventFixture() -> [String: EventsConfig] {
        var events = try! JSONDecoder().decode([String: EventsConfig].self, from: data)

        // Adding Stub event
        events[StubEvent.Constnats.name] = EventsConfig(
            id: 2000,
            supportedOnOptitrack: true,
            supportedOnRealTime: true,
            parameters: [
                StubEvent.Constnats.key : Parameter(
                    type: "String",
                    optiTrackDimensionId: 20,
                    optional: false
                )
            ]
        )
        return events
    }

    func loggerConfigFixture() -> LoggerConfig {
        return LoggerConfig(
                tenantID: StubVariables.int,
                logServiceEndpoint: StubVariables.url
        )
    }

    func customDimensionIDsFixture() -> CustomDimensionIDs {
        return CustomDimensionIDs(
                eventIDCustomDimensionID: 6,
                eventNameCustomDimensionID: 7,
                visitCustomDimensionsStartID: 1,
                maxVisitCustomDimensions: 5,
                actionCustomDimensionsStartID: 8,
                maxActionCustomDimensions: 25
        )
    }

    func firebaseProjectKeysFixture() -> FirebaseProjectKeys {
        return FirebaseProjectKeys(
                appid: StubVariables.string,
                webApiKey: StubVariables.string,
                dbUrl: StubVariables.string,
                senderId: StubVariables.string,
                storageBucket: StubVariables.string,
                projectId: StubVariables.string
        )
    }

    func clientsServiceProjectKeysFixture() -> ClientsServiceProjectKeys {
        return ClientsServiceProjectKeys(
                appid: StubVariables.string,
                webApiKey: StubVariables.string,
                dbUrl: StubVariables.string,
                senderId: StubVariables.string,
                storageBucket: StubVariables.string,
                projectId: StubVariables.string
        )
    }

    func eventsFuxture() -> [String: EventsConfig] {
        return events
    }

}

/// Helps to fetch JSON files.
protocol FileAccessible: class {
    /// The name of the json name.
    var fileName: String { get }
    /// Returns Data from JSON file if exists.
    var data: Data { get }
}

extension FileAccessible {

    var data: Data {
        let bundle = Bundle(for: type(of: self))
        guard let url = bundle.url(forResource: fileName, withExtension: "") else {
            fatalError("File name: \(fileName) does not exist.")
        }
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to fetch data from file: \(fileName).")
        }
        return data
    }

}

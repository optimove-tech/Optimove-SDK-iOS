//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveSDK

let configurationFixture: () -> Configuration = {
    return Configuration(
        tenantID: StubVariables.int,
        logger: loggerConfigFixture(),
        realtime: realtimeConfigFixture(),
        optitrack: optitrackConfigFixture(),
        optipush: optipushConfigFixture()
    )
}

let loggerConfigFixture: () -> LoggerConfig = {
    return LoggerConfig(
        tenantID: StubVariables.int,
        logServiceEndpoint: StubVariables.url
    )
}

let realtimeConfigFixture: () -> RealtimeConfig = {
    return RealtimeConfig(
        tenantID: StubVariables.int,
        realtimeToken: StubVariables.string,
        realtimeGateway: StubVariables.url
    )
}

let optitrackConfigFixture: () -> OptitrackConfig = {
    return OptitrackConfig(
        tenantID: StubVariables.int,
        optitrackEndpoint: StubVariables.url,
        enableAdvertisingIdReport: StubVariables.bool,
        eventCategoryName: StubVariables.string,
        customDimensionIDS: customDimensionIDsFixture()
    )
}

let customDimensionIDsFixture: () -> CustomDimensionIDs = {
    return CustomDimensionIDs(
        eventIDCustomDimensionID: 6,
        eventNameCustomDimensionID: 7,
        visitCustomDimensionsStartID: 1,
        maxVisitCustomDimensions: 5,
        actionCustomDimensionsStartID: 8,
        maxActionCustomDimensions: 25
    )
}

let optipushConfigFixture: () -> OptipushConfig = {
    return OptipushConfig(
        tenantID: StubVariables.int,
        registrationServiceEndpoint: StubVariables.url,
        pushTopicsRegistrationEndpoint: StubVariables.url,
        firebaseProjectKeys: firebaseProjectKeysFixutre(),
        clientsServiceProjectKeys: clientsServiceProjectKeysFixutre()
    )
}

let firebaseProjectKeysFixutre: () -> FirebaseProjectKeys = {
    return FirebaseProjectKeys(
        appid: StubVariables.string,
        webApiKey: StubVariables.string,
        dbUrl: StubVariables.string,
        senderId: StubVariables.string,
        storageBucket: StubVariables.string,
        projectId: StubVariables.string
    )
}

let clientsServiceProjectKeysFixutre: () -> ClientsServiceProjectKeys = {
    return ClientsServiceProjectKeys(
        appid: StubVariables.string,
        webApiKey: StubVariables.string,
        dbUrl: StubVariables.string,
        senderId: StubVariables.string,
        storageBucket: StubVariables.string,
        projectId: StubVariables.string
    )
}

////  Copyright © 2019 Optimove. All rights reserved.

import Foundation
@testable import OptimoveCore

struct StubVariables {
    static let int = 42
    static let string = "string"
    static let bool = true
    static let url = URL(string: "http://8.8.8.8/")!
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

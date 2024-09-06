//  Copyright © 2024 Optimove. All rights reserved.

import Foundation

public struct SdkState {
    public let appVersion: String
    public let sdkVersion: String
    public let installation: String
    public let tenant: String
    public let initialVisitor: String
    public let customer: String
    public let email: String
    public let updateVisitor: String

    static let empty = SdkState(
        appVersion: "",
        sdkVersion: "",
        installation: "",
        tenant: "",
        initialVisitor: "",
        customer: "",
        email: "",
        updateVisitor: ""
    )
}

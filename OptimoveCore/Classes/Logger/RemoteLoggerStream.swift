//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

public final class RemoteLoggerStream: MutableLoggerStream {

    public var policy: LoggerStreamPolicy = .all

    public var tenantId: Int
    public var endpoint: URL = Endpoints.Logger.defaultEndpint

    private let appNs: String
    private let platform: SdkPlatform = .ios

    public init(tenantId: Int) {
        self.tenantId = tenantId
        self.appNs = Bundle.main.bundleIdentifier!
    }

    public func log(
        level: LogLevelCore,
        fileName: String,
        methodName: String,
        logModule: String?,
        message: String
    ) {
        let data = LogBody(
            tenantId: self.tenantId,
            appNs: self.appNs,
            sdkEnv: SDK.environment,
            sdkPlatform: platform,
            level: level,
            logModule: "",
            logFileName: fileName,
            logMethodName: methodName,
            message: message
        )
        if let request = self.buildLogRequest(data) {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                // TODO: Add local logging.
            }
            task.resume()
        }
    }

    private func buildLogRequest(_ data: LogBody) -> URLRequest? {
        if let logBody = try? JSONEncoder().encode(data) {
            var request = URLRequest(url: self.endpoint)
            request.httpBody = logBody
            // FIXME: Move to local Constants.
            request.httpMethod = "POST"
            // FIXME: Move to local Constants.
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            return request
        } else {
            return nil
        }
    }
}

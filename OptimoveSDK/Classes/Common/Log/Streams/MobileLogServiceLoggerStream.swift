//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

final class MobileLogServiceLoggerStream: MutableOptiLoggerOutputStream {

    var tenantId: Int
    var endpoint = Endpoints.Logger.defaultEndpint
    private let appNs: String
    private let sdkPlatform: SdkPlatform

    var isVisibleToClient: Bool {
        return false
    }

    init(tenantId: Int) {
        self.tenantId = tenantId
        self.sdkPlatform = .ios
        self.appNs = Bundle.main.bundleIdentifier!
    }

    func log(level: LogLevel, fileName: String, methodName: String, logModule: String?, message: String) {
        let data = LogBody(
            tenantId: self.tenantId,
            appNs: self.appNs,
            sdkEnv: SDK.environment,
            sdkPlatform: self.sdkPlatform,
            level: level,
            logModule: "",
            logFileName: fileName,
            logMethodName: methodName,
            message: message
        )
        if let request = try? self.buildLogRequest(data) {
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

            }
            task.resume()
        }
    }

    private func buildLogRequest(_ data: LogBody) throws -> URLRequest {
        let logBody = try JSONEncoder().encode(data)
        var request = URLRequest(url: endpoint)
        request.httpBody = logBody
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }
}

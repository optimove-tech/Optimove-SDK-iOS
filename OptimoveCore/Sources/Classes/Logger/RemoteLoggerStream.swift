//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import os.log

public final class RemoteLoggerStream: MutableLoggerStream {

    private struct Constants {
        static let httpHeaders: [String: String] = [
            "Content-Type": "application/json"
        ]
        static let httpMethod = "POST"
    }

    public var policy: LoggerStreamFilter {
        return LoggerStreamFilter.custom { [unowned self] (level, isRemote) -> Bool in
            return self.isAllowedByFiltring(level: level) && isRemote
        }
    }

    public var tenantId: Int
    public var endpoint: URL = Endpoints.Logger.defaultEndpint
    public var isProductionLogsEnabled = false

    private let appNs: String
    private let platform: SdkPlatform = .ios

    private var category: String { return String(describing: type(of: self)) }
    private var log: OSLog { return OSLog(subsystem: OSLog.subsystem, category: category) }

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
            tenantId: tenantId,
            appNs: appNs,
            sdkPlatform: platform,
            level: level,
            logModule: nil,
            logFileName: fileName,
            logMethodName: methodName,
            message: message
        )
        do {
            let request = try buildLogRequest(data)
            let task = URLSession.shared.dataTask(with: request) { [log] (data, response, error) in
                if error != nil {
                    os_log("Logger: data task returns an error '%s'", log: log, type: .error, error!.localizedDescription)
                }
            }
            task.resume()
        } catch {
            print(error.localizedDescription)
        }
    }

    private func buildLogRequest(_ data: LogBody) throws -> URLRequest {
        let logBody = try JSONEncoder().encode(data)
        var request = URLRequest(url: endpoint)
        request.httpBody = logBody
        request.httpMethod = Constants.httpMethod
        Constants.httpHeaders.forEach { (header) in
            request.setValue(header.value, forHTTPHeaderField: header.key)
        }
        return request
    }

    private func isAllowedByFiltring(level: LogLevelCore) -> Bool {
        let defaultState = level >= .error
        return defaultState && isProductionLogsEnabled
    }
}

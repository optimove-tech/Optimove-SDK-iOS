//  Copyright © 2019 Optimove. All rights reserved.

import Foundation
import OptimoveCore

protocol RealTimeRequestBuildable {
    func createReportEventRequest(event: RealtimeEvent, gateway: URL) throws -> NetworkRequest
}

final class RealTimeRequestBuilder {

    struct Constants {
        static let timeoutInterval: TimeInterval = 30
        struct Paths {
            static let reportEvent = "reportEvent"
        }
    }

    private func log(_ request: NetworkRequest) {
        do {
            OptiLoggerMessages.logRealtimeReportEvent(
                json: try cast(String(data: request.httpBody ?? Data(), encoding: .utf8))
            )
        } catch {
            OptiLoggerMessages.logError(error: error)
        }
    }
}

extension RealTimeRequestBuilder: RealTimeRequestBuildable {

    func createReportEventRequest(event: RealtimeEvent, gateway: URL) throws -> NetworkRequest {
        let request = try NetworkRequest(
            method: .post,
            baseURL: gateway,
            path: Constants.Paths.reportEvent,
            body: event,
            timeoutInterval: Constants.timeoutInterval
        )
        log(request)
        return request
    }
}

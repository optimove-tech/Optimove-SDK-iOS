// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class RealTimeRequestBuilderTests: XCTestCase {

    let configuration = configurationFixture()
    var builder: RealTimeRequestBuilder!

    override func setUp() {
        builder = RealTimeRequestBuilder()
    }

    func test_report_event() {
        // given
        let event = RealtimeEvent(
            tid: "tid",
            cid: "cid",
            visitorId: "visitorId",
            eid: "eid",
            context: [ "key": "value"],
            firstVisitorDate: 0
        )

        // when
        XCTAssertNoThrow(try builder.createReportEventRequest(event: event, gateway: configuration.realtime.realtimeGateway))
        let request = try! builder.createReportEventRequest(event: event, gateway: configuration.realtime.realtimeGateway)

        // then
        XCTAssert(request.method == HTTPMethod.post)
        XCTAssert(request.baseURL == configuration.realtime.realtimeGateway)
        XCTAssert(request.path == RealTimeRequestBuilder.Constants.Paths.reportEvent)
        XCTAssert(request.timeoutInterval == RealTimeRequestBuilder.Constants.timeoutInterval)
    }

}

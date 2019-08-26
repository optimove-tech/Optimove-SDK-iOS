//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
import Mocker
@testable import OptimoveSDK

class RealTimeNetworkingTests: XCTestCase {

    var networking: RealTimeNetworking!
    let url = StubVariables.url

    override func setUp() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockingURLProtocol.self]
        let client = NetworkClientImpl(configuration: configuration)
        networking = RealTimeNetworkingImpl(
            networkClient: client,
            realTimeRequestBuildable: RealTimeRequestBuilder(),
            configuration: ConfigurationFixture.build().realtime
        )
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

        // and
        Mocker.register(
            Mock(
                url: url.appendingPathComponent(RealTimeRequestBuilder.Constants.Paths.reportEvent),
                contentType: .json,
                statusCode: 200,
                data: [.post: Data()]
            )
        )

        // when
        let resultExpectation = expectation(description: "Result was not generated.")
        try! networking.report(event: event) { (result) in
            switch result {
            case .success:
                resultExpectation.fulfill()
            case .failure:
                XCTFail()
            }
        }

        // then
        wait(for: [resultExpectation], timeout: expectationTimeout)
    }

}

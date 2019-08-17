//  Copyright © 2019 Optimove. All rights reserved.

import XCTest
@testable import OptimoveSDK

class RegistartionMbaasModelTests: XCTestCase {

    func test_encode_visitor() {
        let model = RegistartionMbaasModel(
            isMbaasOptIn: true,
            fcmToken: "fcmToken",
            osVersion: "osVersion",
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID"),
            deviceId: "deviceId",
            appNs: "appNs"
        )

        XCTAssertNoThrow(try JSONEncoder().encode(model))
    }

    func test_encode_decode_visitor() {
        let model = RegistartionMbaasModel(
            isMbaasOptIn: true,
            fcmToken: "fcmToken",
            osVersion: "osVersion",
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID"),
            deviceId: "deviceId",
            appNs: "appNs"
        )

        do {
            let data = try JSONEncoder().encode(model)
            let decodedModel = try JSONDecoder().decode(RegistartionMbaasModel.self, from: data)
            XCTAssert(model == decodedModel)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_encode_customer() {
        let model = RegistartionMbaasModel(
            isMbaasOptIn: true,
            fcmToken: "fcmToken",
            osVersion: "osVersion",
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            ),
            deviceId: "deviceId",
            appNs: "appNs"
        )

        XCTAssertNoThrow(try JSONEncoder().encode(model))
    }

    func test_encode_decode_customer() {
        let model = RegistartionMbaasModel(
            isMbaasOptIn: true,
            fcmToken: "fcmToken",
            osVersion: "osVersion",
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            ),
            deviceId: "deviceId",
            appNs: "appNs"
        )

        do {
            let data = try JSONEncoder().encode(model)
            let decodedModel = try JSONDecoder().decode(RegistartionMbaasModel.self, from: data)
            XCTAssert(model == decodedModel)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_decode_from_visitor_regester_template() {
        let data = """
        {
          "registration_data": {
            "tenant_id": 85,
            "visitor_id": "32862a06-cdcd-4f75-ace4-a721aea02c95",
            "ios_token": {
              "2b14fa8b-abcf-4347-aca9-ea3e03be657e": {
                "apps": {
                  "app_ns_com": {
                    "opt_in": true,
                    "token": "152 Bytes"
                  }
                },
                "os_version": "7.02"
              }
            }
          }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(RegistartionMbaasModel.self, from: data))
    }

    func test_decode_from_customer_regester_template() {
        let data = """
        {
          "registration_data": {
            "tenant_id": 85,
            "public_customer_id": "32862a06-cdcd-4f75-ace4-a721aea02c98",
            "is_conversion": false,
            "orig_visitor_id": "ef3b6e8b-89c3-47fe-9d05-3b254e7e040f",
            "ios_token": {
              "2b14fa8b-abcf-4347-aca9-ea3e03be657e": {
                "apps": {
                  "app_ns_com": {
                    "opt_in": true,
                    "token": "152 Bytes"
                  }
                },
                "os_version": "7.02"
              }
            }
          }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(RegistartionMbaasModel.self, from: data))
    }

}

// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class MbaasModelTests: XCTestCase {

    func test_encode_visitor() {
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optIn,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        XCTAssertNoThrow(try JSONEncoder().encode(model))
    }

    func test_encode_decode_visitor() {
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optIn,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.visitorID("visitorID")
        )

        do {
            let data = try JSONEncoder().encode(model)
            let decodedModel = try JSONDecoder().decode(MbaasModel.self, from: data)
            XCTAssert(model == decodedModel)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_encode_customer() {
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optIn,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            )
        )

        XCTAssertNoThrow(try JSONEncoder().encode(model))
    }

    func test_encode_decode_customer() {
        let model = MbaasModel(
            deviceId: "deviceId",
            appNs: "appNs",
            operation: .optIn,
            tenantId: 100,
            userIdPayload: BaseMbaasModel.UserIdPayload.customerID(
                BaseMbaasModel.UserIdPayload.CustomerIdPayload(
                    customerID: "customerID",
                    isConversion: true,
                    initialVisitorId: "initialVisitorId"
                )
            )
        )

        do {
            let data = try JSONEncoder().encode(model)
            let decodedModel = try JSONDecoder().decode(MbaasModel.self, from: data)
            XCTAssert(model == decodedModel)
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func test_decode_from_visitor_opt_in_template() {
        let data = """
        {
            "opt_in": {
              "tenant_id": 85,
              "visitor_id": "eb3b6e8b-97b3-47fe-9d05-3b134e7e040f",
              "ios_token": {
                "device_id": "2b14fa8b-abcf-4347-aca9-ea3e03be657e",
                "app_ns": "app_ns_org"
              }
            }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(MbaasModel.self, from: data))
    }

    // test_decode_from_customer_opt_in_template is unreal.

    func test_decode_from_visitor_opt_out_template() {
        let data = """
        {
          "opt_out": {
            "tenant_id": 85,
            "visitor_id": "32862a06-cdcd-4f75-ace4-a721aea02c98",
            "ios_token": {
              "device_id": "2b14fa8b-abcf-4347-aca9-ea3e03be657e",
              "app_ns": "app_ns_com"
            }
          }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(MbaasModel.self, from: data))
    }

    func test_decode_from_customer_opt_out_template() {
        let data = """
        {
            "opt_out": {
                "tenant_id": 85,
                "public_customer_id": "32862a06-cdcd-4f75-ace4-a721aea02c98",
                "ios_token": {
                    "device_id": "2b14fa8b-abcf-4347-aca9-ea3e03be657e",
                    "app_ns": "app_ns_com"
                }
            }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(MbaasModel.self, from: data))
    }

    func test_decode_from_visitor_unregister_template() {
        let data = """
        {
            "unregistration_data": {
                "tenant_id": 85,
                "visitor_id": "32862a06-cdcd-4f75-ace4-a721aea02c95",
                "ios_token": {
                    "device_id": "2b14fa8b-abcf-4347-aca9-ea3e03be657e",
                    "app_ns": "app_ns_com"
                }
            }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(MbaasModel.self, from: data))
    }

    func test_decode_from_customer_unregister_template() {
        let data = """
        {
            "unregistration_data": {
                "tenant_id": 85,
                "public_customer_id": "32862a06-cdcd-4f75-ace4-a721aea02c98",
                "ios_token": {
                 "device_id": "2b14fa8b-abcf-4347-aca9-ea3e03be657e",
                 "app_ns": "app_ns_org"
                }
            }
        }
        """.data(using: .utf8)!

        XCTAssertNoThrow(try JSONDecoder().decode(MbaasModel.self, from: data))
    }
}

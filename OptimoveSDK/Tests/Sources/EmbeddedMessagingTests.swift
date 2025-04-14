//import XCTest
//import Foundation
//@testable import opti // Replace with the name of your app module
//
//class EmbeddedMessagesServiceTests: XCTestCase {
//
//    // Mock response for testing
//    let mockSuccessData = "Success".data(using: .utf8)
//    let mockFailureError = NSError(domain: "com.optimove", code: -1, userInfo: [NSLocalizedDescriptionKey: "Error occurred"])
//
//    // Test getEmbeddedMessagesAsync method
//    func testGetEmbeddedMessagesAsync_Success() {
//        let expectation = self.expectation(description: "Fetching embedded messages")
//
//        // Assuming the completion handler returns a success with mock data
//        EmbeddedMessagesService.getEmbeddedMessagesAsync(
//            customerId: "opt__003",
//            visitorId: "Optimove",
//            tenantId: "3013",
//            brandId: "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc",
//            region: "dev",
//            bodyData: nil
//        ) { result in
//            switch result {
//            case .success(let data):
//                // Test the returned data
//                XCTAssertNotNil(data)
//                XCTAssertEqual(data, self.mockSuccessData)
//            case .failure(let error):
//                XCTFail("Expected success, but got error: \(error)")
//            }
//            expectation.fulfill()
//        }
//
//        // Mocking URLSession shared data task to return mockSuccessData
//        URLSession.shared.dataTask = { _, _, _ in
//            return self.mockSuccessData
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//
//    func testGetEmbeddedMessagesAsync_Failure() {
//        let expectation = self.expectation(description: "Fetching embedded messages - failure")
//
//        // Simulate a failure in the API call
//        EmbeddedMessagesService.getEmbeddedMessagesAsync(
//            customerId: "opt__003",
//            visitorId: "Optimove",
//            tenantId: "3013",
//            brandId: "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc",
//            region: "dev",
//            bodyData: nil
//        ) { result in
//            switch result {
//            case .success(let data):
//                XCTFail("Expected failure, but got success with data: \(data)")
//            case .failure(let error):
//                XCTAssertEqual(error.localizedDescription, "Error occurred")
//            }
//            expectation.fulfill()
//        }
//
//        // Mock failure response
//        URLSession.shared.dataTask = { _, _, error in
//            return error
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//
//    // Test deleteMessageAsync method
//    func testDeleteMessageAsync_Success() {
//        let expectation = self.expectation(description: "Deleting message")
//
//        // Assuming deleteMessageAsync returns a success with mock data
//        EmbeddedMessagesService.deleteMessageAsync(
//            messageId: "message123",
//            tenantId: "3013",
//            brandId: "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc",
//            region: "dev"
//        ) { result in
//            switch result {
//            case .success(let data):
//                XCTAssertNotNil(data)
//                XCTAssertEqual(data, self.mockSuccessData)
//            case .failure(let error):
//                XCTFail("Expected success, but got error: \(error)")
//            }
//            expectation.fulfill()
//        }
//
//        // Mocking URLSession shared data task to return mockSuccessData
//        URLSession.shared.dataTask = { _, _, _ in
//            return self.mockSuccessData
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//
//    func testDeleteMessageAsync_Failure() {
//        let expectation = self.expectation(description: "Deleting message - failure")
//
//        // Simulate a failure in the delete API call
//        EmbeddedMessagesService.deleteMessageAsync(
//            messageId: "message123",
//            tenantId: "3013",
//            brandId: "9abb8d6d-62ed-42d1-97d1-c82d15f9c1fc",
//            region: "dev"
//        ) { result in
//            switch result {
//            case .success(let data):
//                XCTFail("Expected failure, but got success with data: \(data)")
//            case .failure(let error):
//                XCTAssertEqual(error.localizedDescription, "Error occurred")
//            }
//            expectation.fulfill()
//        }
//
//        // Mock failure response
//        URLSession.shared.dataTask = { _, _, error in
//            return error
//        }
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//
//    // Test setReadAsync method
//    func testSetReadAsync_Success() {
//        let expectation = self.expectation(description: "Setting message read status")
//
//        let mockMessage = EmbeddedMessage(id: "message123", engagementId: "engagement123", executionDateTime: "2025-04-14T12:00:00", campaignKind: .push, customerId: "customer123", readAt: "1234567890")
//
//        EmbeddedMessagesService.setReadAsync(from: mockMessage)
//
//        // Assuming the response will be printed in the console, we can just assert it runs without error
//        // Check that the URLRequest is created properly (this is often done via mocking/stubbing in real unit tests)
//
//        expectation.fulfill()
//
//        waitForExpectations(timeout: 5, handler: nil)
//    }
//}

//  Copyright © 2023 Optimove. All rights reserved.

import XCTest
@testable import OptimoveNotificationServiceExtension

final class OptimoveNotificationServiceExtensionTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    // MARK: - getPictureExtension Tests
    
    func testGetPictureExtension_withWebURLWithExtension() {
        // Given a web URL with a jpg extension
        let pictureUrl = "https://example.com/image.jpg"
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then
        XCTAssertEqual(fileExtension, ".jpg")
    }
    
    func testGetPictureExtension_withWebURLWithoutExtension() {
        // Given a web URL without extension
        let pictureUrl = "https://example.com/image"
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then
        XCTAssertNil(fileExtension)
    }
    
    func testGetPictureExtension_withLocalPathWithExtension() {
        // Given a local file path with a png extension
        let pictureUrl = "/path/to/local/image.png"
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then
        XCTAssertEqual(fileExtension, ".png")
    }
    
    func testGetPictureExtension_withLocalPathWithoutExtension() {
        // Given a local file path without extension
        let pictureUrl = "/path/to/local/image"
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then
        XCTAssertNil(fileExtension)
    }
    
    func testGetPictureExtension_withNil() {
        // Given a nil URL
        let pictureUrl: String? = nil
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then
        XCTAssertNil(fileExtension)
    }
    
    func testGetPictureExtension_withInvalidURL() {
        // Given an invalid URL with special characters
        let pictureUrl = "https://example.com/image with spaces.jpg"
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then - should still extract extension using fileURLWithPath fallback
        XCTAssertEqual(fileExtension, ".jpg")
    }
    
    func testGetPictureExtension_withSuggestedFilename() {
        // Given a suggested filename from response
        let suggestedFilename = "downloaded_image.png"

        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(suggestedFilename)
        
        // Then
        XCTAssertEqual(fileExtension, ".png")
    }
    
    func testGetPictureExtension_withQueryParams() {
        // Given a URL with query parameters
        let pictureUrl = "https://example.com/image.jpeg?width=300&height=200"
        
        // When
        let fileExtension = OptimoveNotificationService.getPictureExtension(pictureUrl)
        
        // Then
        XCTAssertEqual(fileExtension, ".jpeg")
    }
}

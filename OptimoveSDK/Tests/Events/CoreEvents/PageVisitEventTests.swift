// Copiright 2019 Optimove

import XCTest
@testable import OptimoveSDK

class PageVisitEventTests: XCTestCase {

    func test_event_name() {
        // given
        let customURL = "customURL"
        let pageTitle = "pageTitle"
        let category = "category"

        // when
        let event = PageVisitEvent(
            customURL: customURL,
            pageTitle: pageTitle,
            category: category
        )

        // then
        XCTAssert(event.name == PageVisitEvent.Constants.name)
    }

    func test_event_parameters() {
        // given
        let customURL = "customURL"
        let pageTitle = "pageTitle"
        let category = "category"

        // when
        let event = PageVisitEvent(
            customURL: customURL,
            pageTitle: pageTitle,
            category: category
        )
        // then
        XCTAssert(event.parameters[PageVisitEvent.Constants.Key.customURL] as? String == customURL)
        XCTAssert(event.parameters[PageVisitEvent.Constants.Key.pageTitle] as? String == pageTitle)
        XCTAssert(event.parameters[PageVisitEvent.Constants.Key.category] as? String == category)
    }

    func test_event_parameters_with_nils() {
        // given
        let customURL = "customURL"

        // when
        let event = PageVisitEvent(
            customURL: customURL,
            pageTitle: nil,
            category: nil
        )
        // then
        XCTAssert(event.parameters[PageVisitEvent.Constants.Key.customURL] as? String == customURL)
    }

}

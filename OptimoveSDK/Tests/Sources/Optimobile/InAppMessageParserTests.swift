import XCTest
@testable import OptimoveSDK

final class InAppMessageParserTests: XCTestCase {

    private let dateParser = InAppMessageParser.makeDateParser()

    private func validMessage(overrides: [AnyHashable: Any] = [:]) -> [AnyHashable: Any] {
        var message: [AnyHashable: Any] = [
            "id": NSNumber(value: 42),
            "content": ["html": "<p>Hello</p>"] as NSDictionary,
            "updatedAt": "2026-08-06T12:00:00Z",
            "presentedWhen": "immediately",
        ]
        for (key, value) in overrides {
            message[key] = value
        }
        return message
    }

    // MARK: - Valid payload

    func testParsesValidMessage() {
        let parsed = InAppMessageParser.parseRequiredFields(from: validMessage(), dateParser: dateParser)

        XCTAssertEqual(parsed?.id, 42)
        XCTAssertEqual(parsed?.presentedWhen, "immediately")
        XCTAssertEqual(parsed?.content["html"] as? String, "<p>Hello</p>")
        XCTAssertNotNil(parsed?.updatedAt)
    }

    func testParsesLargeNumericId() {
        let message = validMessage(overrides: ["id": NSNumber(value: Int64.max)])
        let parsed = InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser)

        XCTAssertEqual(parsed?.id, Int64.max)
    }

    // MARK: - content (crash regression)

    func testRejectsMissingContent() {
        var message = validMessage()
        message.removeValue(forKey: "content")

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    func testRejectsNullContent() {
        let message = validMessage(overrides: ["content": NSNull()])

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    func testRejectsStringContent() {
        let message = validMessage(overrides: ["content": "<p>not a dictionary</p>"])

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    func testRejectsArrayContent() {
        let message = validMessage(overrides: ["content": ["a", "b"]])

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    // MARK: - id

    func testRejectsMissingId() {
        var message = validMessage()
        message.removeValue(forKey: "id")

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    func testRejectsStringId() {
        let message = validMessage(overrides: ["id": "42"])

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    // MARK: - updatedAt / presentedWhen

    func testRejectsMissingUpdatedAt() {
        var message = validMessage()
        message.removeValue(forKey: "updatedAt")

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    func testRejectsInvalidUpdatedAt() {
        let message = validMessage(overrides: ["updatedAt": "not-a-date"])

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }

    func testRejectsMissingPresentedWhen() {
        var message = validMessage()
        message.removeValue(forKey: "presentedWhen")

        XCTAssertNil(InAppMessageParser.parseRequiredFields(from: message, dateParser: dateParser))
    }
}

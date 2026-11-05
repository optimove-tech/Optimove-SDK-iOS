import CoreData
import XCTest
@testable import OptimoveSDK

final class InAppPresenterTests: XCTestCase {

    private static let oneHour: TimeInterval = 60 * 60

    private var presenter: InAppPresenter!

    override func setUp() {
        super.setUp()
        presenter = InAppPresenter(displayMode: .paused, urlBuilder: UrlBuilder(storage: KeyValPersistenceHelper.self))
    }

    private static let messageEntityDescription: NSEntityDescription = {
        let entity = NSEntityDescription()
        entity.name = "Message"
        entity.managedObjectClassName = NSStringFromClass(InAppMessageEntity.self)

        func attribute(_ name: String, _ type: NSAttributeType, optional: Bool = true) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = optional
            return attribute
        }

        entity.properties = [
            attribute("id", .integer64AttributeType, optional: false),
            attribute("updatedAt", .dateAttributeType, optional: false),
            attribute("presentedWhen", .stringAttributeType, optional: false),
            attribute("content", .transformableAttributeType, optional: false),
            attribute("data", .transformableAttributeType),
            attribute("badgeConfig", .transformableAttributeType),
            attribute("inboxConfig", .transformableAttributeType),
            attribute("dismissedAt", .dateAttributeType),
            attribute("inboxFrom", .dateAttributeType),
            attribute("inboxTo", .dateAttributeType),
            attribute("expiresAt", .dateAttributeType),
            attribute("readAt", .dateAttributeType),
            attribute("sentAt", .dateAttributeType),
        ]
        return entity
    }()

    private func message(id: Int64, expiresAt: Date?) -> InAppMessage {
        let entity = InAppMessageEntity(entity: Self.messageEntityDescription, insertInto: nil)
        entity.id = id
        entity.updatedAt = NSDate()
        entity.presentedWhen = InAppPresented.IMMEDIATELY.rawValue
        entity.content = NSDictionary()
        entity.expiresAt = expiresAt as NSDate?
        return InAppMessage(entity: entity)
    }

    private func hoursFromNow(_ hours: Double) -> Date {
        Date(timeIntervalSinceNow: hours * Self.oneHour)
    }

    private func queuedIds() -> [Int64] {
        let queue = Mirror(reflecting: presenter!).children
            .first { $0.label == "messageQueue" }?
            .value as? NSOrderedSet
        return (queue?.array as? [InAppMessage])?.map(\.id) ?? []
    }

    func testMessageWithoutExpiryIsNotExpired() {
        XCTAssertFalse(message(id: 1, expiresAt: nil).isExpired())
    }

    func testMessageWithFutureExpiryIsNotExpired() {
        XCTAssertFalse(message(id: 1, expiresAt: hoursFromNow(1)).isExpired())
    }

    func testMessageWithPastExpiryIsExpired() {
        XCTAssertTrue(message(id: 1, expiresAt: hoursFromNow(-1)).isExpired())
    }

    func testExpiredMessagesAreDroppedFromTheQueueBeforePresentation() {
        presenter.queueMessagesForPresentation(
            messages: [
                message(id: 1, expiresAt: hoursFromNow(-2)),
                message(id: 2, expiresAt: hoursFromNow(-1)),
                message(id: 3, expiresAt: hoursFromNow(1)),
            ],
            tickleIds: NSOrderedSet()
        )

        XCTAssertEqual(queuedIds(), [3])
    }

    func testMessageThatExpiresWhileQueuedIsDroppedOnNextPresentation() {
        let queued = message(id: 1, expiresAt: hoursFromNow(1))
        presenter.queueMessagesForPresentation(messages: [queued], tickleIds: NSOrderedSet())
        XCTAssertEqual(queuedIds(), [1])

        queued.expiresAt = hoursFromNow(-1) as NSDate
        presenter.presentFromQueue()

        XCTAssertEqual(queuedIds(), [])
    }

    func testMessageWithoutExpiryStaysQueuedAcrossPresentations() {
        presenter.queueMessagesForPresentation(messages: [message(id: 1, expiresAt: nil)], tickleIds: NSOrderedSet())

        presenter.presentFromQueue()

        XCTAssertEqual(queuedIds(), [1])
    }

    func testInboxOpenedCopyKeepsAnExpiredQueuedMessage() {
        let queued = message(id: 1, expiresAt: hoursFromNow(1))
        presenter.queueMessagesForPresentation(messages: [queued], tickleIds: NSOrderedSet())
        queued.expiresAt = hoursFromNow(-1) as NSDate

        presenter.queueMessagesForPresentation(messages: [message(id: 1, expiresAt: nil)], tickleIds: NSOrderedSet())

        XCTAssertEqual(queuedIds(), [1])
    }
}

//  Copyright © 2023 Optimove. All rights reserved.

@testable import OptimoveNotificationServiceExtension
import XCTest
import OptimoveTest

final class CategoryManagerTests: XCTestCase {
    var categoryManager: CategoryManager!

    override func setUpWithError() throws {
        categoryManager = CategoryManager(storage: MockOptimoveStorage())
    }

    func test_category_id() {
        let id = CategoryManager.getCategoryId(messageId: 123)
        XCTAssertEqual(id, "__kumulos_category_123__")
    }

    func test_read_dynamic_categories() async throws {
        let categories = categoryManager.readCategoryIds()
        XCTAssertEqual(categories.count, 0)
    }

    func test_write_dynamic_categories() async throws {
        let categories = categoryManager.readCategoryIds()
        XCTAssertEqual(categories.count, 0)

        categoryManager.writeCategoryIds(["category1", "category2"])

        let newCategories = categoryManager.readCategoryIds()
        XCTAssertEqual(newCategories.count, 2)
    }

    func test_filter_pruned_categories() async throws {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "category1", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "category2", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "category3", actions: [], intentIdentifiers: [], options: []),
        ]
        let categoryIds = Set(["category1", "category2", "category3"])

        let (prunedCategories, prunedCategoryIds) = categoryManager.maybePruneCategories(
            categories: categories,
            categoryIds: categoryIds
        )

        XCTAssertEqual(prunedCategories.count, 3)
        XCTAssertEqual(prunedCategoryIds.count, 3)
    }

    func test_filter_pruned_categories_with_limit() async throws {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "category1", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "category2", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "category3", actions: [], intentIdentifiers: [], options: []),
        ]
        let categoryIds = Set(["category1", "category2", "category3"])

        let (prunedCategories, prunedCategoryIds) = categoryManager.maybePruneCategories(
            categories: categories,
            categoryIds: categoryIds,
            limit: 2
        )

        XCTAssertEqual(prunedCategories.count, 2)
        XCTAssertEqual(prunedCategoryIds.count, 2)
    }
}

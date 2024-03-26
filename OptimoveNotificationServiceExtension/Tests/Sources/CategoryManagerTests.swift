//  Copyright © 2023 Optimove. All rights reserved.

@testable import OptimoveNotificationServiceExtension
import XCTest

final class CategoryManagerTests: XCTestCase {
    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: CategoryManager.Constants.DYNAMIC_CATEGORY)
    }

    func test_category_id() {
        let id = CategoryManager.getCategoryId(messageId: 123)
        XCTAssertEqual(id, "__kumulos_category_123__")
    }

    func test_read_dynamic_categories() async throws {
        let categories = CategoryManager.readCategoryIds()
        XCTAssertEqual(categories.count, 0)
    }

    func test_write_dynamic_categories() async throws {
        let categories = CategoryManager.readCategoryIds()
        XCTAssertEqual(categories.count, 0)

        CategoryManager.writeCategoryIds(["category1", "category2"])

        let newCategories = CategoryManager.readCategoryIds()
        XCTAssertEqual(newCategories.count, 2)
    }

    func test_filter_pruned_categories() async throws {
        let categories: Set<UNNotificationCategory> = [
            UNNotificationCategory(identifier: "category1", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "category2", actions: [], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: "category3", actions: [], intentIdentifiers: [], options: []),
        ]
        let categoryIds = Set(["category1", "category2", "category3"])

        let (prunedCategories, prunedCategoryIds) = CategoryManager.maybePruneCategories(
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

        let (prunedCategories, prunedCategoryIds) = CategoryManager.maybePruneCategories(
            categories: categories,
            categoryIds: categoryIds,
            limit: 2
        )

        XCTAssertEqual(prunedCategories.count, 2)
        XCTAssertEqual(prunedCategoryIds.count, 2)
    }
}

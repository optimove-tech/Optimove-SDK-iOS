//  Copyright © 2022 Optimove. All rights reserved.

import OptimoveCore
import UserNotifications

struct CategoryManager {
    enum Constants {
        static let MAX_DYNAMIC_CATEGORIES = 128
    }

    let storage: KeyValueStorage

    init(storage: KeyValueStorage) {
        self.storage = storage
    }

    static func getCategoryId(messageId: Int) -> String {
        return "__kumulos_category_\(messageId)__"
    }

    func registerCategory(_ category: UNNotificationCategory) async {
        var systemCategories = await UNUserNotificationCenter.current().notificationCategories()
        var storedCategoryIds = readCategoryIds()

        systemCategories.insert(category)
        storedCategoryIds.insert(category.identifier)

        let (categories, categoryIds) = maybePruneCategories(categories: systemCategories, categoryIds: storedCategoryIds)

        UNUserNotificationCenter.current().setNotificationCategories(categories)
        writeCategoryIds(categoryIds)

        // Force a reload of the categories
        await UNUserNotificationCenter.current().notificationCategories()
    }

    func readCategoryIds() -> Set<String> {
        let array: [String] = storage[.dynamicCategory] ?? []
        return Set(array)
    }

    func writeCategoryIds(_ ids: Set<String>) {
        storage.set(value: Array(ids), key: .dynamicCategory)
    }

    func maybePruneCategories(
        categories: Set<UNNotificationCategory>,
        categoryIds: Set<String>,
        limit: Int = Constants.MAX_DYNAMIC_CATEGORIES
    ) -> (categories: Set<UNNotificationCategory>, categoryIds: Set<String>) {
        if categoryIds.count <= limit, categories.count <= limit {
            return (categories: categories, categoryIds: categoryIds)
        }

        let categoriesToRemove = categoryIds.prefix(categoryIds.count - limit)
        let prunedCategories = categories.filter { !categoriesToRemove.contains($0.identifier) }
        let prunedCategoryIds = categoryIds.subtracting(categoriesToRemove)

        return (categories: prunedCategories, categoryIds: prunedCategoryIds)
    }
}

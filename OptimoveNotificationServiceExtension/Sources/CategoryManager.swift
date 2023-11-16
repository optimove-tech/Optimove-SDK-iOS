//  Copyright © 2022 Optimove. All rights reserved.

import Foundation
import UserNotifications

let MAX_DYNAMIC_CATEGORIES = 128
let DYNAMIC_CATEGORY_IDENTIFIER = "__kumulos_category_%d__"

@available(iOS 10.0, *)
class CategoryManager {
    let categoryReadLock = DispatchSemaphore(value: 0)
    let dynamicCategoryLock = DispatchSemaphore(value: 1)

    fileprivate static var instance: CategoryManager?

    static var sharedInstance: CategoryManager {
        if instance == nil {
            instance = CategoryManager()
        }

        return instance!
    }

    static func getCategoryIdForMessageId(messageId: Int) -> String {
        return String(format: DYNAMIC_CATEGORY_IDENTIFIER, messageId)
    }

    static func registerCategory(category: UNNotificationCategory) {
        var categorySet = sharedInstance.getExistingCategories()
        var storedDynamicCategories = sharedInstance.getExistingDynamicCategoriesList()

        categorySet.insert(category)
        storedDynamicCategories.append(category.identifier)

        sharedInstance.pruneCategoriesAndSave(categories: categorySet, dynamicCategories: storedDynamicCategories)

        // Force a reload of the categories
        _ = sharedInstance.getExistingCategories()
    }

    fileprivate func getExistingCategories() -> Set<UNNotificationCategory> {
        var returnedCategories = Set<UNNotificationCategory>()

        UNUserNotificationCenter.current().getNotificationCategories { (categories: Set<UNNotificationCategory>) in
            returnedCategories = Set<UNNotificationCategory>(categories)

            self.categoryReadLock.signal()
        }

        _ = categoryReadLock.wait(timeout: DispatchTime.now() + DispatchTimeInterval.seconds(5))

        return returnedCategories
    }

    fileprivate func getExistingDynamicCategoriesList() -> [String] {
        dynamicCategoryLock.wait()
        defer {
            dynamicCategoryLock.signal()
        }

        if let existingArray = UserDefaults.standard.object(forKey: OptimobileUserDefaultsKey.DYNAMIC_CATEGORY.rawValue) {
            return existingArray as! [String]
        }

        let newArray = [String]()

        UserDefaults.standard.set(newArray, forKey: OptimobileUserDefaultsKey.DYNAMIC_CATEGORY.rawValue)

        return newArray
    }

    fileprivate func pruneCategoriesAndSave(categories: Set<UNNotificationCategory>, dynamicCategories: [String]) {
        if dynamicCategories.count <= MAX_DYNAMIC_CATEGORIES {
            UNUserNotificationCenter.current().setNotificationCategories(categories)
            UserDefaults.standard.set(dynamicCategories, forKey: OptimobileUserDefaultsKey.DYNAMIC_CATEGORY.rawValue)
            return
        }

        let categoriesToRemove = dynamicCategories.prefix(dynamicCategories.count - MAX_DYNAMIC_CATEGORIES)

        let prunedCategories = categories.filter { category -> Bool in
            categoriesToRemove.firstIndex(of: category.identifier) == nil
        }

        let prunedDynamicCategories = dynamicCategories.filter { cat -> Bool in
            categoriesToRemove.firstIndex(of: cat) == nil
        }

        UNUserNotificationCenter.current().setNotificationCategories(prunedCategories)
        UserDefaults.standard.set(prunedDynamicCategories, forKey: OptimobileUserDefaultsKey.DYNAMIC_CATEGORY.rawValue)
    }
}

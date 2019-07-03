import Foundation
import OptiTrackCore

class OptimoveQueue: Queue {
    private var items = [Event]()

    public var eventCount: Int {
        return items.count
    }

    func enqueue(events: [Event], completion: (() -> Void)?) {
        OptiLoggerMessages.logAddEventsFromQueue()
        items.append(contentsOf: events)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let eventJson = try encoder.encode(items)
            OptimoveFileManager.save(data: eventJson, toFileName: "pendingOptimoveEvents.json")
        } catch {
            OptiLoggerMessages.logEventsfileCouldNotLoad()
        }
        completion?()
    }

    func first(limit: Int, completion: ([Event]) -> Void) {
        let amount = [limit, eventCount].min()!
        let dequeuedItems = Array(items[0..<amount])
        completion(dequeuedItems)
    }

    func remove(events: [Event], completion: () -> Void) {
        OptiLoggerMessages.logRemoveEventsFromQueue()
        items
            = items.filter({ event in
            !events.contains(where: { eventToRemove in
                eventToRemove.uuid == event.uuid
            })
        })
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let eventJson = try encoder.encode(items)
            OptimoveFileManager.save(data: eventJson, toFileName: "pendingOptimoveEvents.json")
        } catch {
            OptiLoggerMessages.logEventFileSaveFailure()
        }
        completion()
    }
}

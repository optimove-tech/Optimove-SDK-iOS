//  Copyright © 2019 Optimove. All rights reserved.

import Foundation

struct RingBuffer<T> {
    private var array: [T?]
    private var readIndex = 0
    private var writeIndex = 0

    init(count: Int) {
        array = [T?](repeating: nil, count: count)
    }

    /* Returns false if out of space. */
    @discardableResult
    mutating func write(_ element: T) -> Bool {
        guard !isFull else { return false }
        defer {
            writeIndex += 1
        }
        array[wrapped: writeIndex] = element
        return true
    }

    /* Returns nil if the buffer is empty. */
    mutating func read() -> T? {
        guard !isEmpty else { return nil }
        defer {
            array[wrapped: readIndex] = nil
            readIndex += 1
        }
        return array[wrapped: readIndex]
    }

    private var availableSpaceForReading: Int {
        return writeIndex - readIndex
    }

    var isEmpty: Bool {
        return availableSpaceForReading == 0
    }

    private var availableSpaceForWriting: Int {
        return array.count - availableSpaceForReading
    }

    var isFull: Bool {
        return availableSpaceForWriting == 0
    }
}

extension RingBuffer: Sequence {
    func makeIterator() -> AnyIterator<T> {
        var index = readIndex
        return AnyIterator {
            guard index < self.writeIndex else { return nil }
            defer {
                index += 1
            }
            return self.array[wrapped: index]
        }
    }
}

extension Array {
    subscript(wrapped index: Int) -> Element {
        get {
            return self[index % count]
        }
        set {
            self[index % count] = newValue
        }
    }
}

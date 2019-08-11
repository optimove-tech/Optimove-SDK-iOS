//
//  OptimoveEventDecoratorFactory.swift
//  FirebaseCore

import Foundation

final class OptimoveEventDecoratorFactory {
    static func getEventDecorator(forEvent event: OptimoveEvent) -> OptimoveEventDecorator {
        if event is OptimoveCoreEvent {
            return OptimoveEventDecorator(event: event)
        } else {
            return OptimoveCustomEventDecorator(event: event)
        }
    }

    static func getEventDecorator(forEvent event: OptimoveEvent, withConfig config: EventsConfig)
        -> OptimoveEventDecorator
    {
        let dec = getEventDecorator(forEvent: event)
        dec.processEventConfig(config)
        return dec
    }

    private init() {}
}

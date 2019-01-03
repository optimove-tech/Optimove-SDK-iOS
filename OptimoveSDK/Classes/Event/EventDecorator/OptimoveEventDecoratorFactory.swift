//
//  OptimoveEventDecoratorFactory.swift
//  FirebaseCore
//
//  Created by Elkana Orbach on 31/10/2018.
//

import Foundation

class OptimoveEventDecoratorFactory {
    static func getEventDecorator(forEvent event:OptimoveEvent) -> OptimoveEventDecorator {
        if event is OptimoveCoreEvent {
            return OptimoveEventDecorator(event: event)
        } else {
            return OptimoveCustomEventDecorator(event: event)
        }
    }
    
    static func getEventDecorator(forEvent event:OptimoveEvent, withConfig config:OptimoveEventConfig) -> OptimoveEventDecorator {
        let dec = getEventDecorator(forEvent: event)
        dec.processEventConfig(config)
        return dec
    }

    private init(){}
}

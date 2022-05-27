//
//  ThreeWStorage.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import Foundation

private let threeWEventsKey = "threeWEvents"

final class ThreeWStorage: ObservableObject {
    fileprivate let userDefaults: UserDefaults

    @Published var events: [ThreeWEvent] = [] {
        didSet {
            (try? JSONEncoder().encode(events)).flatMap { userDefaults.set($0, forKey: threeWEventsKey) }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        events = userDefaults.data(forKey: threeWEventsKey).flatMap { try? JSONDecoder().decode([ThreeWEvent].self, from: $0) } ?? []
    }

    @Published var eventRunningTimer: [String: Timer] = [:]

    private var defaultName: String { "Action" }
    private var newName: String {
        for i in 1 ..< Int.max {
            let comparedName = i == 1 ? defaultName : (defaultName + " \(i)")
            if events.contains(where: { $0.name == comparedName }) {
                continue
            }
            return comparedName
        }
        return defaultName + " " + UUID().uuidString.prefix(10)
    }

    func newEvent(id: String) -> ThreeWEvent {
        var newEvent = ThreeWEvent.defaultEvent(withID: id)
        newEvent.name = newName
        events.append(newEvent)
        return newEvent
    }
}

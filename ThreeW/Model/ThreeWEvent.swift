//
//  ThreeWEvent.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import Foundation

struct ThreeWEvent: Codable {
    enum When: Codable {
        case next(hour: Int, minute: Int, second: Int)
        case timeAfter(hour: Int, minute: Int, second: Int)
        case specific(date: Date)
    }

    enum Which: Codable {
        case app(name: String, id: String)
        case none
    }

    struct What: Codable {
        enum Action: Codable {
            struct KeycodeModifier: Codable {
                var command: Bool = false
                var option: Bool = false
                var shift: Bool = false
                var control: Bool = false

                var decorationCodes: String {
                    var decorationKeys: [String] = []
                    if command {
                        decorationKeys.append("command")
                    }
                    if option {
                        decorationKeys.append("option")
                    }
                    if shift {
                        decorationKeys.append("shift")
                    }
                    if control {
                        decorationKeys.append("control")
                    }
                    let using = decorationKeys.map { $0 + " down" }.joined(separator: ",")
                    return decorationKeys.isEmpty ? "" : "using {\(using)}"
                }
            }

            struct KeyboardAction: Codable {
                var keycodes: [Int]
                var modifier: KeycodeModifier
            }

            case keycode(KeyboardAction)
//            case record(KeyboardAction)

            var actionString: String {
                switch self {
                case .keycode(let keyboardAction)/*, .record(let keyboardAction) */:
                    let keycodes = keyboardAction.keycodes.map { String($0) }.joined(separator: ",")
                    let decorationCodes = keyboardAction.modifier.decorationCodes
                    return "key code {\(keycodes)}" + (decorationCodes.isEmpty ? "" : " \(decorationCodes)")
                }
            }
        }

        var actions: [Action]
        internal init(actions: [ThreeWEvent.What.Action]) {
            self.actions = actions
        }
    }

    let id: String
    var name: String
    var when: When
    var which: Which
    var what: What

    static func defaultEvent(withID id: String = "") -> ThreeWEvent {
        .init(id: id, name: "", when: .next(hour: 9, minute: 41, second: 0), which: .none, what: .init(actions: []))
    }
}

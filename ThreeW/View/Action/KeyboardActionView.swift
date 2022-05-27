//
//  KeyboardActionView.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import SwiftUI

struct KeycodesParseStrategy: ParseStrategy {
    func parse(_ value: String) throws -> [Int] {
        return value
            .filter { $0.isNumber || $0 == "," }
            .components(separatedBy: ",")
            .compactMap { Int($0) }
    }
}

struct KeycodesFormatStyle: ParseableFormatStyle {
    var parseStrategy: KeycodesParseStrategy {
        .init()
    }

    func format(_ value: [Int]) -> String {
        value.map { String($0) }.joined(separator: ",")
    }
}

struct KeyboardActionView: View {
    @Binding var action: ThreeWEvent.What.Action.KeyboardAction

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Keycodes separated by comma", value: $action.keycodes, format: KeycodesFormatStyle())
                .font(.body)
                .frame(width: 200)

            HStack() {
                Toggle("⌘", isOn: $action.modifier.command)
                    .frame(width: 45)
                Toggle("⌥", isOn: $action.modifier.option)
                    .frame(width: 45)
                Toggle("⇧", isOn: $action.modifier.shift)
                    .frame(width: 45)
                Toggle("⌃", isOn: $action.modifier.control)
                    .frame(width: 45)
            }
        }
    }
}

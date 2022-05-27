//
//  ActionView.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import SwiftUI

struct ActionView: View {
    @Binding var action: ThreeWEvent.What.Action

    var body: some View {
        switch action {
        case .keycode:
            KeyboardActionView(action: keyboardActionBinding)
        }
    }

    var keyboardActionBinding: Binding<ThreeWEvent.What.Action.KeyboardAction> {
        .init {
            guard case let .keycode(keyboardAction) = action else {
                return .init(keycodes: [], modifier: .init())
            }
            return keyboardAction
        } set: { keyboardAction in
            guard case .keycode = action else {
                return
            }
            action = .keycode(keyboardAction)
        }
    }
}

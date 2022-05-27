//
//  RecorderView.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import Cocoa
import Foundation
import SwiftUI
import ShortcutRecorder
import Combine

//class RecorderDelegator: NSObject, RecorderControlDelegate {
//    func recorderControlDidEndRecording(_ aControl: RecorderControl) {
//
//    }
//}
//
//struct RecorderView: NSViewRepresentable {
//    typealias NSViewType = RecorderControl
//
//    let delegator = RecorderDelegator()
//    @Binding 
//
//    func makeNSView(context: Context) -> RecorderControl {
//        let control = RecorderControl()
//        control.set(allowedModifierFlags: [.control, .command, .shift, .option], requiredModifierFlags: [], allowsEmptyModifierFlags: true)
//        control.allowsModifierFlagsOnlyShortcut = true
//        control.delegate = delegator
//        return control
//    }
//
//    func updateNSView(_ nsView: RecorderControl, context: Context) {
//
//    }
//}

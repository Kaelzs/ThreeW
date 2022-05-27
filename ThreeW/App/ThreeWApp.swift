//
//  ThreeWApp.swift
//  ThreeW
//
//  Created by Kael on 2022/5/17.
//

import SwiftUI

@main
struct ThreeWApp: App {
    let storage = ThreeWStorage()

    var body: some Scene {
        WindowGroup {
            AppView().environmentObject(storage)
        }
    }
}

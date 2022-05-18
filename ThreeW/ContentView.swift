//
//  ContentView.swift
//  ThreeW
//
//  Created by Kael on 2022/5/17.
//

import SwiftUI

class TaskManager {
    var runningTask: DispatchWorkItem?
}

struct ContentView: View {
    enum SelectableApp: Identifiable, Hashable, Comparable {
        case none
        case app(String, NSImage?)

        var rawValue: String {
            switch self {
            case .none:
                return ""
            case let .app(string, _):
                return string
            }
        }

        var id: String {
            rawValue
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(rawValue)
        }

        static func == (lhs: SelectableApp, rhs: SelectableApp) -> Bool {
            return lhs.rawValue == rhs.rawValue
        }

        static func < (lhs: SelectableApp, rhs: SelectableApp) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }

    @AppStorage("hour") var hour: Int = 0
    @AppStorage("minute") var minute: Int = 0
    @AppStorage("second") var second: Int = 0

    @State var selectedApp: SelectableApp = .none
    @AppStorage("selectedAppName") var selectedAppName: String = ""
    @State var availableApps: [SelectableApp] = []

    @AppStorage("keycode") var keycode: String = ""

    @AppStorage("commandOn") var commandOn: Bool = false
    @AppStorage("optionOn") var optionOn: Bool = false
    @AppStorage("controlOn") var controlOn: Bool = false
    @AppStorage("shiftOn") var shiftOn: Bool = false

    @State var isRunning = false

    @State var errorMessage: String? = nil

    let taskManager = TaskManager()

    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 2) {
                Text("When")
                    .bold()
                    .frame(width: 55, alignment: .leading)
                TextField("H", value: $hour, format: .number)
                    .frame(width: 25)
                Text(":")
                TextField("M", value: $minute, format: .number)
                    .frame(width: 25)
                Text(":")
                TextField("S", value: $second, format: .number)
                    .frame(width: 25)
            }
            HStack(spacing: 2) {
                Text("Which")
                    .bold()
                    .frame(width: 45, alignment: .leading)

                Picker("", selection: $selectedApp) {
                    ForEach([.none] + availableApps) { app in
                        if case let .app(name, image) = app {
                            HStack {
                                if let image = image {
                                    Image(nsImage: image)
                                }
                                Text(name)
                            }
                            .tag(app)
                        } else {
                            Text("None")
                                .tag(app)
                        }
                    }
                }
                .onChange(of: selectedApp, perform: { s in
                    selectedAppName = s.rawValue
                })
                .frame(width: 200)
            }

            HStack(alignment: .top, spacing: 2) {
                Text("What")
                    .bold()
                    .frame(width: 55, alignment: .leading)

                VStack(alignment: .leading) {
                    HStack {
                        TextField("Keycode", text: $keycode)
                            .frame(width: 100)

                        Text("Seperated by comma")
                            .font(.footnote)
                            .frame(width: 120)
                    }

                    Button("Keycode list") {
                        NSWorkspace.shared.open(URL(string: "https://eastmanreference.com/complete-list-of-applescript-key-codes")!)
                    }.buttonStyle(.link)

                    HStack {
                        Toggle("command", isOn: $commandOn)
                            .padding(.trailing, 3)
                        Toggle("option", isOn: $optionOn)
                            .padding(.trailing, 3)
                    }
                    HStack {
                        Toggle("control", isOn: $controlOn)
                            .padding(.trailing, 3)
                        Toggle("shift", isOn: $shiftOn)
                            .padding(.trailing, 3)
                    }
                }
            }

            HStack(spacing: 10) {
                Button(isRunning ? "Stop" : "Run") {
                    isRunning ? stop() : start()
                }

                if isRunning {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .scaleEffect(0.5)
                        .frame(width: 20, height: 20)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .padding(20)
        .onAppear {
            fetchAppList()
        }
    }

    private func fetchAppList() {
        var availableApps: [SelectableApp] = NSWorkspace.shared.runningApplications.compactMap { app in
            if let name = app.localizedName,
               !name.isEmpty {
                app.icon?.size = NSSize(width: 20, height: 20)
                return SelectableApp.app(name, app.icon)
            }
            return nil
        }
        availableApps = Array(Set(availableApps)).sorted()
        self.availableApps = availableApps

        if !selectedAppName.isEmpty,
           let existApp = availableApps.first(where: { $0.rawValue == selectedAppName }) {
            selectedApp = existApp
        }
    }

    private func start() {
        isRunning.toggle()

        guard case let .app(appName, _) = selectedApp else {
            errorMessage = "Please select an app first"
            isRunning.toggle()
            return
        }

        guard !keycode.isEmpty,
              !keycode.contains(where: { !"0123456789, ".contains($0) }) else {
            errorMessage = "Please input valid keycode to press"
            isRunning.toggle()
            return
        }

        var decorationKeys: [String] = []
        if commandOn {
            decorationKeys.append("command")
        }
        if optionOn {
            decorationKeys.append("option")
        }
        if controlOn {
            decorationKeys.append("control")
        }
        if shiftOn {
            decorationKeys.append("shift")
        }
        let decorationCodes = decorationKeys.isEmpty ? "" : "using {\(decorationKeys.map { $0 + " down" }.joined(separator: ", "))}"

        let scpt = """
        tell application "System Events"
            repeat
                set targetDate to current date
                set currentDate to current date
                set hours of targetDate to \(hour)
                set minutes of targetDate to \(minute)
                set seconds of targetDate to \(second)

                if targetDate <= currentDate then
                    tell application "\(appName)" to activate
                    key code {\(keycode)} \(decorationCodes)
                    exit repeat
                end if
                delay 1
            end repeat
        end tell
        """

        let script = NSAppleScript(source: scpt)

        errorMessage = nil

        taskManager.runningTask?.cancel()
        taskManager.runningTask = DispatchWorkItem {
            var errorInfo: NSDictionary?
            script?.executeAndReturnError(&errorInfo)
            if let errorInfo = errorInfo,
               let message = errorInfo["NSAppleScriptErrorMessage"] as? String {
                errorMessage = message
            }
            isRunning.toggle()
        }

        DispatchQueue.global(qos: .background).async(execute: taskManager.runningTask!)
    }

    private func stop() {
        isRunning.toggle()
        taskManager.runningTask?.cancel()
        taskManager.runningTask = nil
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//
//  ThreeWInputView.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import SwiftUI

class TaskManager {
    var runningTask: DispatchWorkItem?
}

struct ThreeWInputView: View {
    @EnvironmentObject
    var storage: ThreeWStorage

    let id: String

    @State var event: ThreeWEvent

    @State var isRunning = false
    @State var errorMessage: String? = nil

    let taskManager = TaskManager()

    init(event: ThreeWEvent) {
        self.id = event.id
        self._event = .init(wrappedValue: event)
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 0) {
                    Text("When")
                        .bold()
                        .frame(width: 70, height: 20, alignment: .trailing)
                        .padding(.trailing, 10)

                    Picker("", selection: timeMode) {
                        Text("Next Time").tag(TimeMode.nextTime)
                        Text("Time After").tag(TimeMode.timeAfter)
                        Text("Date").tag(TimeMode.date)
                    }
                    .frame(width: 100, alignment: .leading)
                    .padding(.trailing, 8)

                    switch timeMode.wrappedValue {
                    case .nextTime, .timeAfter:
                        HMSPicker(hms: pickedHMS)
                            .frame(width: 120, alignment: .leading)
                            .padding([.leading, .trailing], 5)
                    case .date:
                        DatePicker("", selection: pickedTime, displayedComponents: .date)
                            .frame(width: 100, alignment: .leading)
                        HMSPicker(hms: pickedHMS)
                            .frame(width: 120, alignment: .leading)
                            .padding([.leading, .trailing], 5)
                    }
                }

                HStack(alignment: .center, spacing: 0) {
                    Text("Which")
                        .bold()
                        .frame(width: 70, height: 20, alignment: .trailing)
                        .padding(.trailing, 10)

                    Picker("", selection: selectedApp) {
                        ForEach(availableApps, id: \.id) { app in
                            HStack {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                }
                                if app.id.isEmpty && app.name.isEmpty {
                                    Text("Please Select an app")
                                } else {
                                    Text(app.name + " (\(app.id)) ")
                                }
                            }
                            .tag(app.id.isEmpty ? ThreeWEvent.Which.none : ThreeWEvent.Which.app(name: app.name, id: app.id))
                        }
                    }
                    .frame(width: 208)
                }

                HStack(alignment: .top, spacing: 0) {
                    Text("What")
                        .bold()
                        .frame(width: 70, height: 20, alignment: .trailing)
                        .padding(.trailing, 10)

                    VStack(alignment: .leading) {
                        ForEach(Array(event.what.actions.enumerated()), id: \.offset) { index, element in
                            VStack(alignment: .leading) {
                                HStack {
                                    Picker("", selection: actionMode(at: index)) {
                                        Text("keycode").tag(ActionMode.keycode)
                                    }
                                    .frame(width: 100, alignment: .leading)

                                    if actionMode(at: index).wrappedValue == .keycode {
                                        Button("list") {
                                            NSWorkspace.shared.open(URL(string: "https://eastmanreference.com/complete-list-of-applescript-key-codes")!)
                                        }.buttonStyle(.link)
                                    }

                                    Spacer()

                                    Button {
                                        set { event in
                                            event.what.actions.remove(at: index)
                                        }
                                    } label: {
                                        Image(systemName: "xmark")
                                    }
                                    .buttonStyle(.link)
                                    .foregroundColor(.primary)
                                }.frame(width: 210)

                                ActionView(action: action(at: index))
                                    .padding(.leading, 8)
                            }

                            Divider()
                                .frame(width: 200)
                                .padding(.leading, 8)
                        }

                        Button("Add") {
                            set { event in
                                event.what.actions.append(.keycode(.init(keycodes: [], modifier: .init())))
                            }
                        }
                        .padding(.leading, 8)
                    }
                }

                HStack(alignment: .top, spacing: 0) {
                    Button(isRunning ? "Stop" : "Run") {
                        isRunning ? stop() : start()
                    }
                    .frame(width: 70, height: 20, alignment: .trailing)
                    .padding(.trailing, 10)

                    if isRunning {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.5)
                            .frame(width: 20, height: 20)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .lineLimit(0)
                            .foregroundColor(.red)
                    }
                }
            }.padding(20)
        }
        .onAppear {
            self.isRunning = storage.eventRunningTimer[self.id] != nil
        }
    }

    private func start() {
        stop()
        let scriptString: String
        let date: Date
        do {
            scriptString = try event.toAppleScript()
            date = try event.when.dateToExecute()
        } catch let inputError as InputError {
            errorMessage = inputError.description
            return
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let script = NSAppleScript(source: scriptString)

        var errorInfo: NSDictionary?
        script?.compileAndReturnError(&errorInfo)

        if let errorInfo = errorInfo,
           let message = errorInfo["NSAppleScriptErrorMessage"] as? String {
            errorMessage = message
            return
        }

        isRunning = true
        errorMessage = nil

        let timer = Timer(fire: date, interval: 0, repeats: false) { _ in
            var errorInfo: NSDictionary?
            script?.executeAndReturnError(&errorInfo)
            if let errorInfo = errorInfo,
               let message = errorInfo["NSAppleScriptErrorMessage"] as? String {
                errorMessage = message
            }
            isRunning.toggle()

            stop()
        }
        RunLoop.main.add(timer, forMode: .common)
        storage.eventRunningTimer[id] = timer
    }

    private func stop() {
        storage.eventRunningTimer[id]?.invalidate()
        storage.eventRunningTimer[id] = nil
        isRunning = false
    }
}

extension ThreeWEvent.Which: Hashable {
    static func == (lhs: ThreeWEvent.Which, rhs: ThreeWEvent.Which) -> Bool {
        switch (lhs, rhs) {
        case let (.app(_, lID), .app(_, rID)):
            return lID == rID
        case (.none, .none):
            return true
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .app(name, id):
            hasher.combine(name)
            hasher.combine(id)
        case .none:
            hasher.combine("")
        }
    }
}

private extension ThreeWInputView {
    var bindingEvent: Binding<ThreeWEvent> {
        .init {
            event
        } set: { newValue in
            set(event: newValue)
        }
    }

    private func set(event newValue: ThreeWEvent) {
        event = newValue
        guard let firstIndex = storage.events.firstIndex(where: { $0.id == id }) else {
            return
        }
        storage.events[firstIndex] = newValue
    }

    private func set(event mutating: (inout ThreeWEvent) -> Void) {
        var event = self.event
        mutating(&event)
        set(event: event)
    }

    enum TimeMode {
        case nextTime
        case timeAfter
        case date

        static func from(when: ThreeWEvent.When) -> Self {
            switch when {
            case .next: return .nextTime
            case .timeAfter: return .timeAfter
            case .specific: return .date
            }
        }
    }

    private func set(timeMode: TimeMode, date: Date?, hms: (Int, Int, Int)) {
        switch timeMode {
        case .nextTime:
            set { event in
                event.when = .next(hour: hms.0, minute: hms.1, second: hms.2)
            }
        case .timeAfter:
            set { event in
                event.when = .timeAfter(hour: hms.0, minute: hms.1, second: hms.2)
            }
        case .date:
            set { event in
                let date = date ?? Date()
                let newDate = Calendar.current.date(bySettingHour: hms.0, minute: hms.1, second: hms.2, of: date) ?? Date()
                event.when = .specific(date: newDate)
            }
        }
    }

    var timeMode: Binding<TimeMode> {
        .init {
            .from(when: event.when)
        } set: { mode in
            guard mode != .from(when: event.when) else {
                return
            }
            set(timeMode: mode, date: Date(), hms: pickedHMS.wrappedValue)
        }
    }

    var pickedTime: Binding<Date> {
        .init {
            (try? event.when.dateToExecute()) ?? Date()
        } set: { date in
            set { event in
                switch timeMode.wrappedValue {
                case .date:
                    let pickedHMSValue = pickedHMS.wrappedValue
                    let newDate = Calendar.current.date(bySettingHour: pickedHMSValue.0, minute: pickedHMSValue.1, second: pickedHMSValue.2, of: date) ?? Date()
                    event.when = .specific(date: newDate)
                default:
                    return
                }
            }
        }
    }

    var pickedHMS: Binding<(Int, Int, Int)> {
        .init {
            switch event.when {
            case let .next(hour, minute, second), let .timeAfter(hour, minute, second):
                return (hour, minute, second)
            case let .specific(date):
                let hms = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
                return (hms.hour!, hms.minute!, hms.second!)
            }
        } set: { hour, minute, second in
            set { event in
                switch timeMode.wrappedValue {
                case .nextTime:
                    event.when = .next(hour: hour, minute: minute, second: second)
                case .timeAfter:
                    event.when = .timeAfter(hour: hour, minute: minute, second: second)
                default:
                    return
                }
            }
        }
    }

    var selectedApp: Binding<ThreeWEvent.Which> {
        bindingEvent.which
    }

    private var availableApps: [(icon: NSImage?, name: String, id: String)] {
        var appDict: [String: (icon: NSImage?, name: String, id: String)] = [:]
        NSWorkspace.shared.runningApplications.forEach { app in
            guard let name = app.localizedName,
                  let id = app.bundleIdentifier else {
                return
            }
            let icon = app.icon ?? NSImage(named: "defaultAppIcon")!
            icon.size = NSSize(width: 20, height: 20)
            appDict[id] = (icon, name, id)
        }
        return [(nil, "", "")] + appDict.values.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }

    enum ActionMode {
        case keycode
//        case record

        static func from(action: ThreeWEvent.What.Action) -> Self {
            switch action {
            case .keycode:
                return .keycode
            }
        }
    }

    func actionMode(at index: Int) -> Binding<ActionMode> {
        .init {
            guard event.what.actions.indices.contains(index) else {
                return .keycode
            }
            return .from(action: event.what.actions[index])
        } set: { actionMode in
            guard actionMode != .from(action: event.what.actions[index]) else {
                return
            }
            switch actionMode {
            case .keycode:
                set { event in
                    event.what.actions[index] = .keycode(.init(keycodes: [], modifier: .init()))
                }
            }
        }
    }

    func action(at index: Int) -> Binding<ThreeWEvent.What.Action> {
        .init {
            guard event.what.actions.indices.contains(index) else {
                return .keycode(.init(keycodes: [], modifier: .init()))
            }
            return event.what.actions[index]
        } set: { action in
            guard event.what.actions.indices.contains(index),
                  actionMode(at: index).wrappedValue == .from(action: action) else {
                return
            }
            set { event in
                event.what.actions[index] = action
            }
        }
    }
}

struct ThreeWInputView_Previews: PreviewProvider {
    static var previews: some View {
        ThreeWInputView(event: .defaultEvent()).environmentObject(ThreeWStorage(userDefaults: UserDefaults()))
    }
}

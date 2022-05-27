//
//  AppView.swift
//  ThreeW
//
//  Created by Kael on 2022/5/27.
//

import SwiftUI

fileprivate struct NameLabel: View {
    @Binding var name: String
    @State var internalName: String
    @State var canEdit = false
    @FocusState var isFocused: Bool

    init(name: Binding<String>) {
        self._name = name
        internalName = name.wrappedValue
    }

    @ViewBuilder
    var textView: some View {
        if canEdit {
            TextField("Event Name", text: $internalName)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    name = internalName
                    DispatchQueue.main.async {
                        if internalName != name {
                            internalName = name
                        }
                    }
                }
                .onAppear {
                    isFocused = true
                }
                .onChange(of: isFocused) { newValue in
                    if !newValue {
                        canEdit = false
                    }
                }
        } else {
            Text(name)
                .simultaneousGesture(TapGesture(count: 2).onEnded {
                    canEdit = true
                })
        }
    }

    var body: some View {
        textView
    }
}

struct AppView: View {
    @EnvironmentObject
    var storage: ThreeWStorage

    @State private var selectedEventID: String?

    @State private var renameErrorAlert: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                List(storage.events, id: \.id) { event in
                    NavigationLink(
                        destination: view(for: event),
                        tag: event.id,
                        selection: $selectedEventID,
                        label: {
                            NameLabel(name: nameBinding(for: event))
                                .simultaneousGesture(TapGesture().onEnded { _ in
                                    if selectedEventID != event.id {
                                        selectedEventID = event.id
                                    }
                                })

                            if storage.eventRunningTimer[event.id] != nil {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.5)
                                    .frame(width: 16, height: 16)
                            }
                        }
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            if selectedEventID == event.id {
                                selectedEventID = nil
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        storage.events.removeAll(where: { $0.id == event.id })
                                    }
                                }
                            } else {
                                withAnimation {
                                    storage.events.removeAll(where: { $0.id == event.id })
                                }
                            }
                        } label: {
                            Text("Delete")
                        }
                    }
                }
                .listStyle(.sidebar)

                Button {
                    withAnimation {
                        let newEvent = storage.newEvent(id: UUID().uuidString)
                        selectedEventID = newEvent.id
                    }
                } label: {
                    Label("Add Event", systemImage: "plus")
                }
                .padding(.bottom, 10)
            }

            Text("Select or create an event")
        }.toolbar {
            ToolbarItem(
                placement: .navigation,
                content: {
                    Button {
                        NSApp.keyWindow?.firstResponder?.tryToPerform(
                            #selector(NSSplitViewController.toggleSidebar(_:)), with: nil
                        )
                    } label: {
                        Label("Toggle sidebar", systemImage: "sidebar.left")
                    }
                }
            )
        }
        .alert("Rename failed, name exists", isPresented: $renameErrorAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    func nameBinding(for event: ThreeWEvent) -> Binding<String> {
        .init {
            guard let event = storage.events.first(where: { $0.id == event.id }) else {
                return ""
            }
            return event.name
        } set: { name in
            guard let index = storage.events.firstIndex(where: { $0.id == event.id }) else {
                return
            }
            if storage.events[index].name != name {
                if storage.events.contains(where: { $0.name == name }) {
                    renameErrorAlert.toggle()
                    return
                }
                storage.events[index].name = name
            }
        }
    }

    @ViewBuilder
    func view(for event: ThreeWEvent) -> some View {
        ThreeWInputView(event: event).environmentObject(storage)
    }
}

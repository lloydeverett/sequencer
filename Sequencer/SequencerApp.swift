import SwiftUI

@main
struct SequencerApp: App {
    @StateObject private var store = SequenceStore()
    @StateObject private var controller = TimerController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(controller)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 380)
        .windowResizability(.contentMinSize)
        .commands {
            // Remove the "New Window" command — this is a single-window utility app
            CommandGroup(replacing: .newItem) {}
        }
    }
}

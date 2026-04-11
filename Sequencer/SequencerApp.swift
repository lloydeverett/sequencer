import SwiftUI

@main
struct SequencerApp: App {
    @StateObject private var store = SequenceStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 300, height: 380)
        .windowResizability(.contentMinSize)
    }
}

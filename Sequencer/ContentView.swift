import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: SequenceStore
    @StateObject private var controller = TimerController()
    /// Each window tracks its own selected tab.
    @State private var selectedIndex: Int = 0

    var body: some View {
        Group {
            if controller.isRunning {
                TimerRunningView(controller: controller)
            } else {
                SequenceEditView(controller: controller, selectedIndex: $selectedIndex)
            }
        }
        // Constrain window size
        .frame(minWidth: 200, maxWidth: .infinity,  minHeight: 250, maxHeight: .infinity)
        // Translucent material background that blurs whatever is behind the window
        .background(.ultraThinMaterial)
        // Wire up the window-level configuration once the view appears
        .background(WindowConfigurator())
        .sheet(item: $store.syncConflict) { conflict in
            SyncConflictView(conflict: conflict)
                .environmentObject(store)
        }
    }
}

// MARK: - Window configurator

/// Thin NSView that grabs its parent window and applies floating + transparency settings.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.level = .floating
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.isOpaque = false
            window.backgroundColor = .clear
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

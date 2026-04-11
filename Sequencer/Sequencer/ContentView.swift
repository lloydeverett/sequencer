import SwiftUI

struct ContentView: View {
    @EnvironmentObject var controller: TimerController

    var body: some View {
        Group {
            if controller.isRunning {
                TimerRunningView(controller: controller)
            } else {
                SequenceEditView(controller: controller)
            }
        }
        // Stretch to fill the window
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Translucent material background that blurs whatever is behind the window
        .background(.ultraThinMaterial)
        // Wire up the window-level configuration once the view appears
        .background(WindowConfigurator())
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

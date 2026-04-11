import SwiftUI

// MARK: - Running timer view

struct TimerRunningView: View {
    @ObservedObject var controller: TimerController

    var body: some View {
        VStack(spacing: 10) {
            Spacer()

            // Timer title
            if let entry = controller.currentEntry {
                Text(entry.title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal)

                // Countdown
                Text(formattedTime(controller.timeRemaining))
                    .font(.system(size: 52, weight: .thin, design: .monospaced))
                    .monospacedDigit()

                // Progress indicator  e.g. "2 / 5"
                if controller.totalCount > 1 {
                    Text("\(controller.currentIndex + 1) of \(controller.totalCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if controller.hasNextEntry {
                Button {
                    controller.skipToNext()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal)
            }

            Button {
                controller.stop()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Helpers

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let s = max(Int(seconds), 0)
        if s >= 3600 {
            return String(format: "%d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
        }
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}

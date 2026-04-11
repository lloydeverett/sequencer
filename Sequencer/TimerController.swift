import Foundation
import AppKit
import Combine

/// Drives the countdown for a sequence of TimerEntry values.
final class TimerController: ObservableObject {
    // MARK: - Published state

    @Published var isRunning: Bool = false
    @Published var currentEntry: TimerEntry? = nil
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentIndex: Int = 0
    @Published var totalCount: Int = 0

    // MARK: - Private

    private var entries: [TimerEntry] = []
    private var timerTask: Timer?
    /// The wall-clock deadline for the current entry to expire.
    private var entryDeadline: Date = .distantFuture

    // MARK: - Public API

    func start(entries: [TimerEntry]) {
        guard !entries.isEmpty else { return }
        self.entries = entries
        totalCount = entries.count
        currentIndex = 0
        beginEntry(at: 0)
    }

    func stop() {
        cancelTimer()
        isRunning = false
        currentEntry = nil
        timeRemaining = 0
    }

    // MARK: - Private helpers

    private func beginEntry(at index: Int) {
        guard index < entries.count else {
            stop()
            return
        }

        cancelTimer()

        currentIndex = index
        let entry = entries[index]
        currentEntry = entry
        timeRemaining = entry.duration
        entryDeadline = Date().addingTimeInterval(entry.duration)
        isRunning = true

        // Open the associated link, if any
        if let url = entry.link {
            NSWorkspace.shared.open(url)
        }

        SoundManager.shared.playStart()

        // Use a high-frequency timer and derive remaining time from the wall clock
        // to avoid accumulated drift on long-running timers.
        timerTask = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let remaining = entryDeadline.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            entryFinished()
        } else {
            // Round up so the display shows e.g. "5" for the full fifth second.
            timeRemaining = ceil(remaining)
        }
    }

    private func entryFinished() {
        cancelTimer()
        SoundManager.shared.playComplete()
        let next = currentIndex + 1
        if next < entries.count {
            beginEntry(at: next)
        } else {
            // All entries done
            isRunning = false
            currentEntry = nil
            timeRemaining = 0
        }
    }

    private func cancelTimer() {
        timerTask?.invalidate()
        timerTask = nil
    }
}

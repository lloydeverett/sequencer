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

    var hasNextEntry: Bool {
        isRunning && (currentIndex + 1) < totalCount
    }

    // MARK: - Private

    private var entries: [TimerEntry] = []
    private var timerTask: Timer?
    /// The wall-clock deadline for the current entry to expire.
    private var entryDeadline: Date = .distantFuture
    private let statusPublisher = TimerStatusFilePublisher()

    // MARK: - Lifecycle

    init() {
        publishStatus()
    }

    deinit {
        statusPublisher.publish(
            TimerStatusSnapshot(
                running: false,
                currentIndex: 0,
                totalCount: totalCount,
                timeRemaining: 0,
                currentTitle: nil,
                updatedAt: Date()
            )
        )
    }

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
        publishStatus()
    }

    func skipToNext() {
        guard hasNextEntry else { return }
        cancelTimer()
        beginEntry(at: currentIndex + 1)
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

        // Execute the associated shell command, if any
        if let command = entry.command {
            executeCommand(command)
        }

        SoundManager.shared.playStart()

        // Use a high-frequency timer and derive remaining time from the wall clock
        // to avoid accumulated drift on long-running timers.
        timerTask = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            self?.tick()
        }

        publishStatus()
    }

    private func tick() {
        let remaining = entryDeadline.timeIntervalSinceNow
        if remaining <= 0 {
            timeRemaining = 0
            publishStatus()
            entryFinished()
        } else {
            // Round up so the display shows e.g. "5" for the full fifth second.
            timeRemaining = ceil(remaining)
            publishStatus()
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
            publishStatus()
        }
    }

    private func cancelTimer() {
        timerTask?.invalidate()
        timerTask = nil
    }

    private func executeCommand(_ command: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["--login", "-c", "[ -f /etc/zshrc ] && . /etc/zshrc; [ -f ~/.zshrc ] && . ~/.zshrc;" + command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
        } catch {
            print("Failed to execute command: \(error)")
        }
    }

    private func publishStatus() {
        statusPublisher.publish(
            TimerStatusSnapshot(
                running: isRunning,
                currentIndex: currentIndex,
                totalCount: totalCount,
                timeRemaining: max(Int(timeRemaining), 0),
                currentTitle: currentEntry?.title,
                updatedAt: Date()
            )
        )
    }
}

private struct TimerStatusSnapshot: Codable, Equatable {
    let running: Bool
    let currentIndex: Int
    let totalCount: Int
    let timeRemaining: Int
    let currentTitle: String?
    let updatedAt: Date
}

private final class TimerStatusFilePublisher {
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()
    private let queue = DispatchQueue(label: "sequencer.status-file")

    private let statusFileURL: URL = {
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        return homeURL.appendingPathComponent(".sequencer/status.json", isDirectory: false)
    }()

    func publish(_ snapshot: TimerStatusSnapshot) {
        queue.async {
            self.publishOnQueue(snapshot)
        }
    }

    private func publishOnQueue(_ snapshot: TimerStatusSnapshot) {
        guard let bodyData = try? encoder.encode(snapshot) else { return }

        let directoryURL = statusFileURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            try bodyData.write(to: statusFileURL, options: .atomic)
        } catch {
            print("Failed to write timer status file: \(error)")
        }
    }
}

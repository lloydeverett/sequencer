import Foundation
import Combine
import AppKit

class SequenceStore: ObservableObject {
    private static let defaultSequences: [TimerSequence] = [
        TimerSequence(name: "Tab 1", text: "25m Work\n5m  Break"),
        TimerSequence(name: "Tab 2", text: ""),
        TimerSequence(name: "Tab 3", text: ""),
    ]

    @Published var sequences: [TimerSequence] {
        didSet {
            guard !isLoadingFromDisk else { return }
            save()
        }
    }

    @Published private(set) var storageDirectory: URL

    private let directoryPathKey = "sequencer.directoryPath"
    private let filename = "sequences.json"
    private var saveTask: DispatchWorkItem?
    private var monitorTimer: Timer?
    private var lastWrittenModificationDate: Date?
    private var isLoadingFromDisk = false

    private var fileURL: URL { storageDirectory.appendingPathComponent(filename) }

    init() {
        let defaultDir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Sequencer")

        let dir: URL
        if let saved = UserDefaults.standard.string(forKey: "sequencer.directoryPath") {
            dir = URL(fileURLWithPath: saved)
        } else {
            dir = defaultDir
        }

        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        storageDirectory = dir

        let fileURL = dir.appendingPathComponent(filename)
        if let decoded = Self.decodedSequences(from: fileURL) {
            sequences = decoded
            lastWrittenModificationDate = try? FileManager.default
                .attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
        } else {
            sequences = Self.defaultSequences
        }
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - File monitoring

    private func startMonitoring() {
        stopMonitoring()
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
            self?.checkForExternalChanges()
        }
    }

    private func stopMonitoring() {
        monitorTimer?.invalidate()
        monitorTimer = nil
    }

    private func checkForExternalChanges() {
        let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path)
        let fileModDate = attrs?[.modificationDate] as? Date

        if let fileModDate, let lastWritten = lastWrittenModificationDate,
           fileModDate > lastWritten {
            reloadFromDisk()
        }
    }

    private func reloadFromDisk() {
        if let decoded = Self.decodedSequences(from: fileURL) {
            isLoadingFromDisk = true
            sequences = decoded
            isLoadingFromDisk = false
            lastWrittenModificationDate = try? FileManager.default
                .attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
        }
    }

    private static func decodedSequences(from url: URL) -> [TimerSequence]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        guard !data.isEmpty else { return nil }
        return try? JSONDecoder().decode([TimerSequence].self, from: data)
    }

    private func loadFromSelectedDirectoryOrInitializeDefaults() {
        if let decoded = Self.decodedSequences(from: fileURL) {
            isLoadingFromDisk = true
            sequences = decoded
            isLoadingFromDisk = false
            lastWrittenModificationDate = try? FileManager.default
                .attributesOfItem(atPath: fileURL.path)[.modificationDate] as? Date
            return
        }

        isLoadingFromDisk = true
        sequences = Self.defaultSequences
        isLoadingFromDisk = false
        save(immediate: true)
    }

    // MARK: - Directory selection

    func openDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.message = "Choose a folder to store your sequences"
        panel.directoryURL = storageDirectory

        if panel.runModal() == .OK, let url = panel.url {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            UserDefaults.standard.set(url.path, forKey: directoryPathKey)
            storageDirectory = url
            loadFromSelectedDirectoryOrInitializeDefaults()
        }
    }

    // MARK: - Tab management

    /// Appends a new tab and returns its index.
    @discardableResult
    func addTab() -> Int {
        let number = sequences.count + 1
        sequences.append(TimerSequence(name: "Tab \(number)"))
        return sequences.count - 1
    }

    func removeTab(at index: Int) {
        guard sequences.count > 1 else { return }
        sequences.remove(at: index)
    }

    func moveTab(from source: Int, to destination: Int) {
        guard source >= 0 && source < sequences.count else { return }
        guard destination >= 0 && destination < sequences.count else { return }
        guard source != destination else { return }
        let sequence = sequences.remove(at: source)
        sequences.insert(sequence, at: destination)
    }

    // MARK: - Persistence

    private func save(immediate: Bool = false) {
        saveTask?.cancel()
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if let data = try? JSONEncoder().encode(self.sequences) {
                try? data.write(to: self.fileURL, options: .atomic)
                self.lastWrittenModificationDate = try? FileManager.default
                    .attributesOfItem(atPath: self.fileURL.path)[.modificationDate] as? Date
            }
        }
        saveTask = task
        if immediate {
            DispatchQueue.global(qos: .utility).async(execute: task)
        } else {
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 1.0, execute: task)
        }
    }
}

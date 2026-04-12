import Foundation
import Combine
import AppKit

class SequenceStore: ObservableObject {
    @Published var sequences: [TimerSequence] {
        didSet { save() }
    }

    @Published private(set) var storageDirectory: URL

    private let directoryPathKey = "sequencer.directoryPath"
    private let filename = "sequences.json"
    private var saveTask: DispatchWorkItem?

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

        let fileURL = dir.appendingPathComponent("sequences.json")
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([TimerSequence].self, from: data) {
            sequences = decoded
        } else {
            sequences = [
                TimerSequence(name: "Tab 1", text: "Work 25m\nBreak 5m"),
                TimerSequence(name: "Tab 2", text: ""),
                TimerSequence(name: "Tab 3", text: ""),
            ]
        }
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
            save(immediate: true)
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

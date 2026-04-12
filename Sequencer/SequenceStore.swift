import Foundation
import Combine

struct SyncConflict: Identifiable {
    let id = UUID()
    let local: [TimerSequence]
    let cloud: [TimerSequence]
}

class SequenceStore: ObservableObject {
    @Published var sequences: [TimerSequence] {
        didSet { save() }
    }
    @Published var syncConflict: SyncConflict?

    private let sequencesKey = "sequencer.sequences"
    private let kvStore = NSUbiquitousKeyValueStore.default

    init() {
        kvStore.synchronize()

        sequences = Self.load(from: NSUbiquitousKeyValueStore.default, key: "sequencer.sequences")
            ?? Self.load(from: UserDefaults.standard, key: "sequencer.sequences")
            ?? [
                TimerSequence(name: "Tab 1", text: "Work 25m\nBreak 5m"),
                TimerSequence(name: "Tab 2", text: ""),
                TimerSequence(name: "Tab 3", text: ""),
            ]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDidChange(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: kvStore
        )
    }

    @objc private func iCloudDidChange(_ notification: Notification) {
        guard syncConflict == nil else { return }
        guard
            let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String],
            keys.contains(sequencesKey),
            let incoming = Self.load(from: kvStore, key: sequencesKey)
        else { return }

        let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if reason == NSUbiquitousKeyValueStoreInitialSyncChange {
                self.syncConflict = SyncConflict(local: self.sequences, cloud: incoming)
            } else {
                self.sequences = incoming
            }
        }
    }

    func resolveConflict(keepCloud: Bool) {
        guard let conflict = syncConflict else { return }
        syncConflict = nil
        sequences = keepCloud ? conflict.cloud : conflict.local
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

    private func save() {
        guard let data = try? JSONEncoder().encode(sequences) else { return }
        kvStore.set(data, forKey: sequencesKey)
        kvStore.synchronize()
        UserDefaults.standard.set(data, forKey: sequencesKey)
    }

    private static func load(from kvStore: NSUbiquitousKeyValueStore, key: String) -> [TimerSequence]? {
        guard let data = kvStore.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([TimerSequence].self, from: data)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [TimerSequence]? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode([TimerSequence].self, from: data)
    }
}

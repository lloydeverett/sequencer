import Foundation
import Combine

class SequenceStore: ObservableObject {
    @Published var sequences: [TimerSequence] {
        didSet { save() }
    }

    private let sequencesKey = "sequencer.sequences"

    init() {
        if let data = UserDefaults.standard.data(forKey: sequencesKey),
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

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sequences) {
            UserDefaults.standard.set(data, forKey: sequencesKey)
        }

    }
}

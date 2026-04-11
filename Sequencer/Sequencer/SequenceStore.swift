import Foundation
import Combine

class SequenceStore: ObservableObject {
    @Published var sequences: [TimerSequence] {
        didSet { save() }
    }

    @Published var selectedIndex: Int = 0 {
        didSet { save() }
    }

    private let sequencesKey = "sequencer.sequences"
    private let selectedKey  = "sequencer.selectedIndex"

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
        selectedIndex = UserDefaults.standard.integer(forKey: selectedKey)
        if selectedIndex >= sequences.count { selectedIndex = 0 }
    }

    // MARK: - Convenience accessors

    var selectedSequence: TimerSequence {
        get {
            guard !sequences.isEmpty else { return TimerSequence(name: "Tab 1") }
            return sequences[clampedIndex]
        }
        set {
            sequences[clampedIndex] = newValue
        }
    }

    private var clampedIndex: Int {
        min(max(selectedIndex, 0), sequences.count - 1)
    }

    // MARK: - Tab management

    func addTab() {
        let number = sequences.count + 1
        sequences.append(TimerSequence(name: "Tab \(number)"))
        selectedIndex = sequences.count - 1
    }

    func removeTab(at index: Int) {
        guard sequences.count > 1 else { return }
        sequences.remove(at: index)
        if selectedIndex >= sequences.count { selectedIndex = sequences.count - 1 }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(sequences) {
            UserDefaults.standard.set(data, forKey: sequencesKey)
        }
        UserDefaults.standard.set(selectedIndex, forKey: selectedKey)
    }
}

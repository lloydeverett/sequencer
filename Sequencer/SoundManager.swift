import AppKit

/// Plays system sounds to signal timer events.
final class SoundManager {
    static let shared = SoundManager()
    private init() {}

    /// Called when a timer in the sequence starts.
    func playStart() {
        NSSound(named: "Tink")?.play()
    }

    /// Called when a timer in the sequence completes.
    func playComplete() {
        NSSound(named: "Glass")?.play()
    }
}

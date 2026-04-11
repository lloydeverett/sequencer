import Foundation

// MARK: - TimerEntry

struct TimerEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var duration: TimeInterval
    var command: String?

    init(id: UUID = UUID(), title: String, duration: TimeInterval, command: String? = nil) {
        self.id = id
        self.title = title
        self.duration = duration
        self.command = command
    }
}

// MARK: - Parsing

extension TimerEntry {
    /// Parse all valid timer entries from a multi-line string.
    static func parseAll(from text: String) -> [TimerEntry] {
        text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("//") }
            .compactMap { parseLine($0) }
    }

    /// Parse a single line into a TimerEntry, returning nil if no valid duration found.
    static func parseLine(_ line: String) -> TimerEntry? {
        // Extract shell command if present (wrapped in square brackets [cmd])
        var command: String? = nil
        var lineWithoutCommand = line
        
        if let matchRange = line.range(of: #"\[(.+?)\]"#, options: .regularExpression) {
            let captured = String(line[matchRange])
            // Extract content between brackets
            let trimmed = captured.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            command = trimmed
            // Remove the bracketed portion from the line for further parsing
            lineWithoutCommand = line.replacingCharacters(in: matchRange, with: "")
        }
        
        var tokens = lineWithoutCommand.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return nil }

        // Extract duration: search from the right for the first token matching the duration pattern
        var duration: TimeInterval? = nil
        for i in stride(from: tokens.count - 1, through: 0, by: -1) {
            if let d = parseDuration(tokens[i]) {
                duration = d
                tokens.remove(at: i)
                break
            }
        }

        guard let duration else { return nil }

        let title = tokens.joined(separator: " ")
        return TimerEntry(
            title: title.isEmpty ? "Timer" : title,
            duration: duration,
            command: command
        )
    }

    /// Parse a duration token such as "10m", "1h30m", "90s", "1h30m45s".
    /// Returns nil if the token doesn't match or the total duration is zero.
    private static func parseDuration(_ token: String) -> TimeInterval? {
        let pattern = #"^(?:(\d+)h)?(?:(\d+)m)?(?:(\d+)s)?$"#
        guard
            let regex = try? NSRegularExpression(pattern: pattern),
            let match = regex.firstMatch(
                in: token,
                range: NSRange(token.startIndex..., in: token)
            )
        else { return nil }

        func group(_ idx: Int) -> Double? {
            let r = match.range(at: idx)
            guard r.location != NSNotFound, let range = Range(r, in: token) else { return nil }
            return Double(token[range])
        }

        let hours = group(1) ?? 0
        let minutes = group(2) ?? 0
        let seconds = group(3) ?? 0
        let total = hours * 3600 + minutes * 60 + seconds
        return total > 0 ? total : nil
    }
}

// MARK: - TimerSequence (a named tab)

struct TimerSequence: Identifiable, Codable {
    let id: UUID
    var name: String
    var text: String

    init(id: UUID = UUID(), name: String, text: String = "") {
        self.id = id
        self.name = name
        self.text = text
    }

    var entries: [TimerEntry] {
        TimerEntry.parseAll(from: text)
    }
}

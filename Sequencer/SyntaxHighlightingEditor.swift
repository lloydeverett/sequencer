import SwiftUI
import AppKit

// MARK: - Syntax-highlighted text editor for timer sequences

struct SyntaxHighlightingEditor: NSViewRepresentable {
    @Binding var text: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let tv = scrollView.documentView as! NSTextView
        tv.delegate = context.coordinator
        tv.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        tv.allowsUndo = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticSpellingCorrectionEnabled = false
        tv.isContinuousSpellCheckingEnabled = false
        tv.isGrammarCheckingEnabled = false
        tv.textContainerInset = NSSize(width: 5, height: 8)
        tv.backgroundColor = .clear
        tv.drawsBackground = false
        scrollView.drawsBackground = false
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let tv = scrollView.documentView as! NSTextView
        guard tv.string != text else { return }
        let savedRanges = tv.selectedRanges
        tv.string = text
        tv.selectedRanges = savedRanges
        applyHighlighting(to: tv)
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        let parent: SyntaxHighlightingEditor
        init(_ p: SyntaxHighlightingEditor) { parent = p }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            parent.applyHighlighting(to: tv)
        }
    }
}

// MARK: - Syntax highlighting rules

private extension SyntaxHighlightingEditor {

    /// Matches all valid duration tokens:  10m  1h30m  1h30m45s  90s  etc.
    static let durationRx = try! NSRegularExpression(
        pattern: #"\b(?:\d+h\d+m\d+s|\d+h\d+m|\d+h\d+s|\d+m\d+s|\d+h|\d+m|\d+s)\b"#
    )
    /// Matches shell-command blocks:  [open Finder]
    static let commandRx = try! NSRegularExpression(
        pattern: #"\[.+?\]"#
    )

    // Semantic colors — adapt automatically to light / dark mode
    static let colorDefault  = NSColor.labelColor                              // valid-line title text
    static let colorInvalid  = NSColor.labelColor.withAlphaComponent(0.5)      // lines with no valid duration
    static let colorComment  = NSColor.systemGreen.withAlphaComponent(0.8)     // // comment lines
    static let colorDuration = NSColor.systemOrange                            // duration tokens
    static let colorCommand  = NSColor.systemCyan                              // [command] blocks

    func applyHighlighting(to tv: NSTextView) {
        guard let storage = tv.textStorage else { return }
        let str = storage.string
        guard !str.isEmpty else { return }

        let nsStr = str as NSString
        let fullRange = NSRange(location: 0, length: nsStr.length)

        storage.beginEditing()

        // 1. Reset everything to the default foreground colour
        storage.addAttribute(.foregroundColor, value: Self.colorDefault, range: fullRange)

        nsStr.enumerateSubstrings(in: fullRange, options: .byLines) { line, lineRange, _, _ in
            guard let line else { return }
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // --- Comment lines ---
            if trimmed.hasPrefix("//") {
                storage.addAttribute(.foregroundColor, value: Self.colorComment, range: lineRange)
                return
            }

            guard !trimmed.isEmpty else { return }

            // --- Invalid lines (won't produce a timer entry) ---
            if TimerEntry.parseLine(trimmed) == nil {
                storage.addAttribute(.foregroundColor, value: Self.colorInvalid, range: lineRange)
            }

            // --- Duration tokens (applied before commands so commands can override on overlap) ---
            Self.durationRx.enumerateMatches(in: str, range: lineRange) { m, _, _ in
                guard let r = m?.range else { return }
                storage.addAttribute(.foregroundColor, value: Self.colorDuration, range: r)
            }

            // --- [command] blocks (applied last; wins over duration colour if they overlap) ---
            Self.commandRx.enumerateMatches(in: str, range: lineRange) { m, _, _ in
                guard let r = m?.range else { return }
                storage.addAttribute(.foregroundColor, value: Self.colorCommand, range: r)
            }
        }

        storage.endEditing()
    }
}

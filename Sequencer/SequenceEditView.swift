import SwiftUI

// MARK: - Sequence edit view (idle state)

struct SequenceEditView: View {
    @EnvironmentObject var store: SequenceStore
    @ObservedObject var controller: TimerController

    /// Index of the tab being renamed; nil when not renaming.
    @State private var renamingIndex: Int? = nil
    @State private var renameText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            tabBar
            Divider()
            editor
            Divider()
            toolbar
        }
    }

    // MARK: - Tab bar

    private var tabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(store.sequences.indices, id: \.self) { idx in
                    tabButton(index: idx)
                }

                // Add-tab button
                Button {
                    store.addTab()
                } label: {
                    Image(systemName: "plus")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 34)
    }

    @ViewBuilder
    private func tabButton(index: Int) -> some View {
        let isSelected = store.selectedIndex == index

        if renamingIndex == index {
            // Inline rename field
            TextField("Tab name", text: $renameText)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .frame(width: 80)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(4)
                .onSubmit { commitRename(at: index) }
                .onExitCommand { renamingIndex = nil }
        } else {
            Button {
                store.selectedIndex = index
            } label: {
                Text(store.sequences[index].name)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(isSelected ? Color.primary.opacity(0.12) : Color.primary.opacity(0.01))
            .cornerRadius(4)
            .contentShape(Rectangle())
            .contextMenu {
                Button("Rename") { beginRename(at: index) }
                Divider()
                Button("Remove Tab", role: .destructive) {
                    store.removeTab(at: index)
                }
                .disabled(store.sequences.count <= 1)
            }
        }
    }

    // MARK: - Text editor

    private var editor: some View {
        TextEditor(text: Binding(
            get: { store.selectedSequence.text },
            set: { store.selectedSequence.text = $0 }
        ))
        .font(.system(.body, design: .monospaced))
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    // MARK: - Bottom toolbar

    private var toolbar: some View {
        HStack {
            let entries = store.selectedSequence.entries
            Text(entrySummary(entries))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Spacer()
            Button {
                controller.start(entries: entries)
            } label: {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(entries.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Rename helpers

    private func beginRename(at index: Int) {
        renameText = store.sequences[index].name
        renamingIndex = index
    }

    private func commitRename(at index: Int) {
        let trimmed = renameText.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            store.sequences[index].name = trimmed
        }
        renamingIndex = nil
    }

    // MARK: - Misc helpers

    private func entrySummary(_ entries: [TimerEntry]) -> String {
        if entries.isEmpty { return "No timers" }
        let total = entries.reduce(0) { $0 + $1.duration }
        return "\(entries.count) timer\(entries.count == 1 ? "" : "s") · \(formatDuration(total))"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let s = Int(seconds)
        if s < 60 { return "\(s)s" }
        if s < 3600 { return "\(s / 60)m" }
        let h = s / 3600
        let m = (s % 3600) / 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h"
    }
}

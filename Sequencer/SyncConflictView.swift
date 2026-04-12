import SwiftUI

struct SyncConflictView: View {
    @EnvironmentObject var store: SequenceStore
    let conflict: SyncConflict

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("iCloud Sync Conflict")
                .font(.headline)

            Text("Your tabs on this device differ from iCloud. Which version would you like to keep?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                SequenceList(label: "This Device", sequences: conflict.local)
                Divider()
                SequenceList(label: "iCloud", sequences: conflict.cloud)
            }

            HStack {
                Button("Keep This Device") { store.resolveConflict(keepCloud: false) }
                    .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Keep iCloud") { store.resolveConflict(keepCloud: true) }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(minWidth: 360)
    }
}

private struct SequenceList: View {
    let label: String
    let sequences: [TimerSequence]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)

            ForEach(sequences) { seq in
                VStack(alignment: .leading, spacing: 2) {
                    Text(seq.name)
                        .font(.callout)
                        .fontWeight(.medium)
                    let count = seq.entries.count
                    Text(count == 0 ? "empty" : "\(count) timer\(count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if sequences.isEmpty {
                Text("No tabs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

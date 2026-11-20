import SwiftData
import SwiftUI

struct LettersView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(PurchaseManager.self) private var purchases
    @Query(sort: [SortDescriptor(\UnsentLetter.createdAt, order: .reverse)]) private var letters: [UnsentLetter]
    @State private var pendingDelete: UnsentLetter?

    var body: some View {
        NavigationStack {
            Group {
                if letters.isEmpty {
                    empty
                } else {
                    list
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .confirmationDialog(
            "Release this letter?",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Release", role: .destructive) {
                if let pendingDelete {
                    modelContext.delete(pendingDelete)
                    try? modelContext.save()
                }
                pendingDelete = nil
            }
            Button("Keep", role: .cancel) {
                pendingDelete = nil
            }
        } message: {
            Text("It will be deleted from this phone.")
        }
    }

    private var empty: some View {
        VStack(spacing: 14) {
            Spacer()
            Text("Nothing locked away")
                .font(AppFont.display(30))
                .foregroundStyle(.white)
            Text("When the urge comes, write it here instead of sending it.")
                .font(AppFont.prose(17))
                .foregroundStyle(.white.opacity(0.66))
                .multilineTextAlignment(.center)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var list: some View {
        List {
            Section {
                ForEach(letters) { letter in
                    NavigationLink {
                        LetterDetailView(letter: letter)
                    } label: {
                        LetterRow(letter: letter)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparatorTint(.white.opacity(0.12))
                    .swipeActions {
                        Button("Release", role: .destructive) {
                            pendingDelete = letter
                        }
                    }
                }
            } footer: {
                Text(footer)
                    .font(AppFont.chrome(13))
                    .foregroundStyle(.white.opacity(0.55))
                    .padding(.top, 8)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .top) {
            ScreenHeader(eyebrow: "unsent", title: "Letters", subtitle: "What you didn't send.")
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }

    private var footer: String {
        if purchases.isUnlocked {
            return "These stay on this phone."
        }
        return "\(letters.count) kept. The free version holds \(AppIdentity.freeLetterLimit)."
    }
}

private struct LetterRow: View {
    let letter: UnsentLetter

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(letter.createdAt.formatted(.dateTime.day().month(.abbreviated).year()))
                .font(AppFont.chrome(12, weight: .medium))
                .foregroundStyle(.white.opacity(0.48))
            Text(letter.text)
                .font(AppFont.prose(17))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(2)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
    }
}

struct LetterDetailView: View {
    let letter: UnsentLetter
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(letter.createdAt.formatted(date: .long, time: .shortened))
                    .font(AppFont.chrome(13))
                    .foregroundStyle(.white.opacity(0.5))
                Text(letter.text)
                    .font(AppFont.prose(22))
                    .foregroundStyle(.white)
                    .lineSpacing(6)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Unsent. On this phone.")
                    .font(AppFont.prose(15))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, 8)
                Button("Release this letter") {
                    confirm = true
                }
                .font(AppFont.chrome(15))
                .foregroundStyle(Color(hex: 0xE7B8A8))
                .padding(.top, 12)
            }
            .padding(24)
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .confirmationDialog(
            "Release this letter?",
            isPresented: $confirm,
            titleVisibility: .visible
        ) {
            Button("Release", role: .destructive) {
                modelContext.delete(letter)
                try? modelContext.save()
                dismiss()
            }
            Button("Keep", role: .cancel) {}
        } message: {
            Text("It will be deleted from this phone.")
        }
    }
}

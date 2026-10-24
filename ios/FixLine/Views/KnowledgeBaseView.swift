import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct KnowledgeBaseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var auth
    @AppStorage("user.role") private var roleRaw: String = UserRole.technician.rawValue

    @Query(sort: \ManualDocument.addedAt, order: .reverse) private var docs: [ManualDocument]

    @State private var showImporter = false
    @State private var importing = false
    @State private var error: String?

    private var role: UserRole { UserRole(rawValue: roleRaw) ?? .technician }
    private var canUpload: Bool { role == .lead || role == .management }
    private var indexedDocs: Int { docs.filter { $0.indexed && !$0.extractedText.isEmpty }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summaryCard

                if let error {
                    errorCard(error)
                }

                if docs.isEmpty {
                    emptyCard
                } else {
                    ForEach(docs) { doc in
                        docRow(doc)
                    }
                }

                if canUpload {
                    Button {
                        Haptics.tap()
                        showImporter = true
                    } label: {
                        if importing {
                            HStack(spacing: 10) {
                                ProgressView().tint(Theme.onPrimary)
                                Text("Extracting text…")
                            }
                        } else {
                            Label("Upload PDF Manual", systemImage: "doc.badge.plus")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(importing)
                    .padding(.top, 4)
                } else {
                    Label("Switch to Lead or Management role to upload manuals.", systemImage: "lock.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
            }
            .padding(16)
            .padding(.bottom, 40)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Knowledge Base")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                importPDFs(urls)
            case .failure(let e):
                error = e.localizedDescription
            }
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PLANT KNOWLEDGE BASE")
                .font(.caption.weight(.heavy))
                .tracking(2)
                .foregroundStyle(Theme.textTertiary)
            Text("\(indexedDocs) of \(docs.count) manuals indexed")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text("The AI reads relevant excerpts from these manuals during every diagnosis.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var emptyCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.primary.opacity(0.6))
            Text("No manuals yet")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text("Upload equipment PDFs — O&M guides, wiring diagrams, fault tables. The AI cites them when diagnosing.")
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .cardStyle()
    }

    private func docRow(_ doc: ManualDocument) -> some View {
        HStack(spacing: 12) {
            Image(systemName: doc.indexed ? "doc.text.fill" : "doc.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(doc.indexed ? Theme.success : Theme.primary)
                .frame(width: 40, height: 40)
                .background(Theme.surfaceElevated)
                .clipShape(.rect(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(doc.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(2)
                HStack(spacing: 8) {
                    Text("\(doc.pageCount) pages")
                    Text("·")
                    Text(doc.extractedText.isEmpty ? "No text layer" : "\(doc.extractedText.count / 1000)k chars")
                    Text("·")
                    Text(doc.addedAt.formatted(date: .abbreviated, time: .omitted))
                }
                .font(.caption.monospaced())
                .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Button {
                Haptics.warning()
                modelContext.delete(doc)
                try? modelContext.save()
            } label: {
                Image(systemName: "trash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.danger)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(12)
        .background(Theme.surface)
        .clipShape(.rect(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.stroke, lineWidth: 1))
    }

    private func errorCard(_ msg: String) -> some View {
        Label(msg, systemImage: "exclamationmark.triangle.fill")
            .font(.caption.weight(.semibold))
            .foregroundStyle(Theme.danger)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
    }

    private func importPDFs(_ urls: [URL]) {
        importing = true
        error = nil
        Task {
            for url in urls {
                let scoped = url.startAccessingSecurityScopedResource()
                let (text, pages) = await Task.detached {
                    ManualLibrary.extractText(from: url)
                }.value
                if scoped { url.stopAccessingSecurityScopedResource() }
                let doc = ManualDocument(
                    title: url.deletingPathExtension().lastPathComponent,
                    fileName: url.lastPathComponent,
                    pageCount: pages,
                    extractedText: text,
                    indexed: !text.isEmpty
                )
                modelContext.insert(doc)
            }
            try? modelContext.save()
            importing = false
            Haptics.success()
        }
    }
}

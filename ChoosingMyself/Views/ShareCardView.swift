import CoreTransferable
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct ShareCard: View {
    let days: Int
    let line: String
    let theme: MoodTheme

    var body: some View {
        ZStack {
            ThemeBackground(theme: theme, animated: false, extendsIntoSafeArea: false)
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                Text(AppIdentity.handle)
                    .font(AppFont.chrome(28, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.62))
                Spacer().frame(height: 36)
                Text("\(days)")
                    .font(AppFont.display(176))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text(AppFormat.unit(for: days))
                    .font(AppFont.prose(48))
                    .foregroundStyle(.white.opacity(0.84))
                Text("of choosing myself")
                    .font(AppFont.prose(44))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.top, 6)
                Spacer().frame(height: 40)
                Rectangle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 72, height: 1)
                Spacer().frame(height: 36)
                Text(line)
                    .font(AppFont.prose(36))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 120)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 220)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .environment(\.colorScheme, .dark)
    }
}

struct MilestoneShare: Identifiable {
    let days: Int
    var id: Int { days }
}

struct SharePreviewSheet: View {
    let days: Int
    let line: String
    let theme: MoodTheme

    @State private var image: UIImage?
    @State private var failed = false

    var body: some View {
        ZStack {
            Color(hex: 0x07090C).ignoresSafeArea()
            VStack(spacing: 18) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 48)
                    if let data = image.pngData() {
                        ShareLink(
                            item: SharedPNG(data: data, days: days),
                            preview: SharePreview(
                                "\(days) \(AppFormat.unit(for: days)) of choosing myself",
                                image: Image(uiImage: image)
                            )
                        ) {
                            Text("Share card")
                                .font(AppFont.prose(17))
                                .foregroundStyle(Color(hex: 0x161412))
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 56)
                                .background(Capsule().fill(Color.white.opacity(0.94)))
                        }
                        .padding(.horizontal, 24)
                    }
                    Text("9:16, for a Story.")
                        .font(AppFont.chrome(13))
                        .foregroundStyle(.white.opacity(0.45))
                } else if failed {
                    Text("The card couldn't be drawn. Try again.")
                        .font(AppFont.prose(17))
                        .foregroundStyle(.white.opacity(0.75))
                } else {
                    ProgressView()
                        .tint(.white)
                }
            }
            .padding(.vertical, 24)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationBackground(Color(hex: 0x07090C))
        .task {
            let rendered = ShareCardRenderer.image(days: days, line: line, theme: theme)
            image = rendered
            failed = rendered == nil
        }
    }
}

@MainActor
enum ShareCardRenderer {
    static func image(days: Int, line: String, theme: MoodTheme) -> UIImage? {
        let card = ShareCard(days: days, line: line, theme: theme)
            .frame(width: 1080, height: 1920)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: 1080, height: 1920)
        renderer.isOpaque = true
        return renderer.uiImage
    }
}

struct SharedPNG: Transferable {
    let data: Data
    let days: Int

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { item in
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("choosing-myself-\(item.days)-days.png")
            try? FileManager.default.removeItem(at: url)
            try item.data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
    }
}

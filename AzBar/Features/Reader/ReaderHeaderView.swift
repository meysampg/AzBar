import SwiftUI

/// Poem title block with a collapsible "about this poem" card.
struct ReaderHeaderView: View {
    let poem: Poem
    let poetName: String

    @State private var isSummaryExpanded = false

    private var hasSummary: Bool { !(poem.summary ?? "").isEmpty }

    private var metaLine: String {
        poem.fullTitle.contains(poetName) || poetName.isEmpty ? poem.fullTitle : "\(poetName) · \(poem.fullTitle)"
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.m) {
            VStack(spacing: Theme.Spacing.s) {
                Text(verbatim: poem.title)
                    .font(.azTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                Text(verbatim: metaLine)
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: Theme.Spacing.s) {
                    Rectangle().fill(Theme.Palette.hairline).frame(height: 1)
                    Image(systemName: "sparkle")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Palette.gold)
                    Rectangle().fill(Theme.Palette.hairline).frame(height: 1)
                }
                .frame(width: 120)
                .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity)

            if hasSummary, let summary = poem.summary {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Button {
                        withAnimation(.smooth(duration: 0.25)) { isSummaryExpanded.toggle() }
                    } label: {
                        HStack {
                            Label {
                                Text("دربارهٔ این شعر")
                                    .font(.azHeadline)
                                    .foregroundStyle(Theme.Palette.ink)
                            } icon: {
                                Image(systemName: "info.circle")
                                    .foregroundStyle(Theme.Palette.teal)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(Theme.Palette.inkSecondary)
                                .rotationEffect(.degrees(isSummaryExpanded ? 180 : 0))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityValue(isSummaryExpanded ? "باز" : "بسته")
                    .accessibilityHint("برای نمایش یا پنهان کردن توضیح بزنید")

                    if isSummaryExpanded {
                        Text(verbatim: summary)
                            .font(.azMeta)
                            .foregroundStyle(Theme.Palette.inkSecondary)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .azCard()
            }
        }
    }
}

#Preview {
    ReaderHeaderView(poem: PreviewFixtures.samplePoem, poetName: "حافظ")
        .padding()
        .azScreenBackground()
        .environment(\.layoutDirection, .rightToLeft)
}

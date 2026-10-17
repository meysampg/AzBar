import SwiftUI

struct AzChip: View {
    let text: String
    var systemImage: String?
    var tone: AzTone

    init(_ text: String, systemImage: String? = nil, tone: AzTone = .neutral) {
        self.text = text
        self.systemImage = systemImage
        self.tone = tone
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 11, weight: .semibold))
                    .accessibilityHidden(true)
            }
            Text(verbatim: text)
                .lineLimit(1)
        }
        .font(.azCaption)
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, Theme.Spacing.s)
        .padding(.vertical, Theme.Spacing.xs)
        .background(tone.soft, in: .capsule)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        AzChip("آفلاین", systemImage: "arrow.down.circle.fill", tone: .teal)
        AzChip("۳ تاج", systemImage: "crown.fill", tone: .gold)
        AzChip("نثر", tone: .neutral)
        AzChip("آموخته شد", systemImage: "checkmark", tone: .success)
        AzChip("۲", systemImage: "snowflake", tone: .info)
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}

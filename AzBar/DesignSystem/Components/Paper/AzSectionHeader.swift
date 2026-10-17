import SwiftUI

struct AzSectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    init(_ title: String, subtitle: String? = nil, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(verbatim: title)
                    .font(.azHeadline)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(verbatim: subtitle)
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
            }
            Spacer(minLength: 0)
            trailing
        }
    }
}

extension AzSectionHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle) { EmptyView() }
    }
}

/// Header text for `List` sections.
struct AzListHeader: View {
    let title: String

    init(_ title: String) { self.title = title }

    var body: some View {
        Text(verbatim: title)
            .font(.app(.subheadline, weight: .semibold))
            .foregroundStyle(Theme.Palette.inkSecondary)
            .textCase(nil)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 20) {
        AzSectionHeader("در حال حفظ")
        AzSectionHeader("دستاوردها", subtitle: "۳ از ۱۵") { AzChip("همه", tone: .teal) }
        AzListHeader("بخش‌ها")
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}

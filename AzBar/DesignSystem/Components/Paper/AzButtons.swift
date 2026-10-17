import SwiftUI

enum AzPrimaryTone: Sendable {
    case teal, success, danger

    var fill: Color {
        switch self {
        case .teal: Theme.Palette.teal
        case .success: Theme.Palette.success
        case .danger: Theme.Palette.danger
        }
    }

    var edge: Color {
        switch self {
        case .teal: Theme.Palette.tealDeep
        case .success: Theme.Palette.successDeep
        case .danger: Theme.Palette.dangerDeep
        }
    }
}

/// Solid brand button with a 4 pt bottom edge; the face sinks onto the edge when pressed.
struct AzPrimaryButtonStyle: ButtonStyle {
    var tone: AzPrimaryTone = .teal
    var compact = false

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, style: self)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        let style: AzPrimaryButtonStyle

        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = configuration.isPressed && isEnabled
            configuration.label
                .font(.azButton)
                .foregroundStyle(isEnabled ? Color.white : Theme.Palette.inkTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, style.compact ? Theme.Spacing.l : Theme.Spacing.m)
                .frame(maxWidth: style.compact ? nil : .infinity, minHeight: style.compact ? 48 : 52)
                .modifier(AzEdgedSurface(
                    fill: isEnabled ? style.tone.fill : Theme.Palette.track,
                    edge: isEnabled ? style.tone.edge : nil,
                    radius: Theme.Radius.control, depth: 4, pressed: pressed))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
                .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, new in new }
        }
    }
}

/// White button with a teal label, a soft teal border and a 3 pt edge.
struct AzSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = configuration.isPressed && isEnabled
            configuration.label
                .font(.app(.callout, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.Palette.teal : Theme.Palette.inkTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(maxWidth: .infinity, minHeight: 48)
                .modifier(AzEdgedSurface(
                    fill: isEnabled ? Theme.Palette.card : Theme.Palette.track,
                    edge: isEnabled ? Color(hex: 0xD5E6E4) : nil,
                    border: isEnabled ? Color(hex: 0xB9D8D6) : nil,
                    radius: Theme.Radius.control, depth: 3, pressed: pressed))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
                .sensoryFeedback(.impact(weight: .light), trigger: pressed) { _, new in new }
        }
    }
}

/// Plain teal text button.
struct AzTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.app(.callout, weight: .semibold))
                .foregroundStyle(isEnabled ? Theme.Palette.teal : Theme.Palette.inkTertiary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 44)
                .opacity(configuration.isPressed ? 0.6 : 1)
                .contentShape(.rect)
        }
    }
}

/// Small capsule on tealSoft («معنی», «پخش این بیت»).
struct AzPillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(.azCaption)
                .foregroundStyle(isEnabled ? Theme.Palette.teal : Theme.Palette.inkTertiary)
                .padding(.horizontal, Theme.Spacing.m)
                .frame(minHeight: 36)
                .background(Theme.Palette.tealSoft, in: .capsule)
                .opacity(configuration.isPressed ? 0.7 : 1)
                .contentShape(.capsule)
        }
    }
}

/// Rating button: soft tone with a deep label and a 3 pt edge; filled tone when suggested.
struct AzRatingButtonStyle: ButtonStyle {
    let rating: Rating
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        Face(configuration: configuration, style: self)
    }

    private struct Face: View {
        let configuration: ButtonStyle.Configuration
        let style: AzRatingButtonStyle
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            let pressed = configuration.isPressed
            let strong = Theme.color(for: style.rating)
            configuration.label
                .foregroundStyle(style.prominent ? Color.white : Theme.deepColor(for: style.rating))
                .padding(.horizontal, Theme.Spacing.xs)
                .modifier(AzEdgedSurface(
                    fill: style.prominent ? strong : Theme.softColor(for: style.rating),
                    edge: strong.opacity(0.35),
                    radius: Theme.Radius.control, depth: 3, pressed: pressed))
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: pressed)
        }
    }
}

extension ButtonStyle where Self == AzPrimaryButtonStyle {
    static var azPrimary: AzPrimaryButtonStyle { AzPrimaryButtonStyle() }
    static func azPrimary(_ tone: AzPrimaryTone = .teal, compact: Bool = false) -> AzPrimaryButtonStyle {
        AzPrimaryButtonStyle(tone: tone, compact: compact)
    }
}

extension ButtonStyle where Self == AzSecondaryButtonStyle {
    static var azSecondary: AzSecondaryButtonStyle { AzSecondaryButtonStyle() }
}

extension ButtonStyle where Self == AzTertiaryButtonStyle {
    static var azTertiary: AzTertiaryButtonStyle { AzTertiaryButtonStyle() }
}

extension ButtonStyle where Self == AzPillButtonStyle {
    static var azPill: AzPillButtonStyle { AzPillButtonStyle() }
}

#Preview {
    VStack(spacing: 14) {
        Button("ادامه") {}.buttonStyle(.azPrimary)
        Button("درست") {}.buttonStyle(.azPrimary(.success))
        Button("نادرست") {}.buttonStyle(.azPrimary(.danger))
        Button("فشرده") {}.buttonStyle(.azPrimary(compact: true))
        Button("غیرفعال") {}.buttonStyle(.azPrimary).disabled(true)
        Button { } label: { Label("نمایش پاسخ", systemImage: "eye") }.buttonStyle(.azSecondary)
        Button("نمی‌دانم") {}.buttonStyle(.azTertiary)
        Button { } label: { Label("معنی", systemImage: "text.bubble") }.buttonStyle(.azPill)
        HStack {
            ForEach(Rating.allCases, id: \.self) { r in
                Button(Theme.title(for: r)) {}.buttonStyle(AzRatingButtonStyle(rating: r, prominent: r == .good))
            }
        }
    }
    .padding(20)
    .azScreenBackground()
    .persianRoot()
}

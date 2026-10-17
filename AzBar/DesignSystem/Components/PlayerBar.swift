import SwiftUI

/// Floating Liquid Glass audio control: play/pause, reciter menu with elapsed/total time, 10 s rewind.
/// Wrap it (together with sibling glass controls) in a `GlassEffectContainer` at the call site.
struct PlayerBar: View {
    let isPlaying: Bool
    let isLoading: Bool
    let currentTime: TimeInterval
    let duration: TimeInterval
    let recitations: [Recitation]
    let selectedRecitationId: Int?
    /// When true only the play/pause button is shown.
    var isCollapsed: Bool = false
    let onToggle: () -> Void
    let onSkipBack: () -> Void
    let onSelect: (Recitation) -> Void

    private var selectedArtist: String {
        recitations.first { $0.id == selectedRecitationId }?.artist ?? recitations.first?.artist ?? ""
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Button(action: onToggle) {
                ZStack {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.title3)
                            .contentTransition(.symbolEffect(.replace))
                    }
                }
                .frame(width: 44, height: 44)
                .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "توقف" : "پخش")

            if !isCollapsed {
                reciterMenu
                Button(action: onSkipBack) {
                    Image(systemName: "gobackward.10")
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .contentShape(.circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("۱۰ ثانیه به عقب")
            }
        }
        .foregroundStyle(.primary)
        .padding(Theme.Spacing.xs)
        .glassEffect(.regular.interactive(), in: .capsule)
        .sensoryFeedback(.impact(weight: .light), trigger: isPlaying)
        .animation(.smooth, value: isCollapsed)
    }

    private var reciterMenu: some View {
        Menu {
            Picker("خوانش", selection: Binding(
                get: { selectedRecitationId ?? -1 },
                set: { id in
                    if let r = recitations.first(where: { $0.id == id }) { onSelect(r) }
                }
            )) {
                ForEach(recitations) { r in
                    Text(verbatim: r.artist).tag(r.id)
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: "خوانش: " + selectedArtist)
                    .font(.app(.caption, weight: .medium))
                    .lineLimit(1)
                Text(verbatim: Self.timeText(currentTime: currentTime, duration: duration))
                    .font(.app(.caption2))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .accessibilityLabel("انتخاب خوانش")
        .accessibilityValue(selectedArtist)
    }

    /// "۰۱:۲۵ / ۰۳:۴۰" with Persian digits.
    static func timeText(currentTime: TimeInterval, duration: TimeInterval) -> String {
        func format(_ t: TimeInterval) -> String {
            let total = max(0, Int(t.isFinite ? t : 0))
            return PersianNumber.digits(String(format: "%02d:%02d", total / 60, total % 60))
        }
        return duration > 0 ? "\(format(currentTime)) / \(format(duration))" : format(currentTime)
    }
}

#Preview("Expanded") {
    GlassEffectContainer {
        PlayerBar(
            isPlaying: true, isLoading: false, currentTime: 85, duration: 220,
            recitations: PreviewFixtures.samplePoem.recitations, selectedRecitationId: 2840,
            onToggle: {}, onSkipBack: {}, onSelect: { _ in }
        )
    }
    .padding()
    .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Collapsed") {
    PlayerBar(
        isPlaying: false, isLoading: false, currentTime: 0, duration: 0,
        recitations: PreviewFixtures.samplePoem.recitations, selectedRecitationId: 2840, isCollapsed: true,
        onToggle: {}, onSkipBack: {}, onSelect: { _ in }
    )
    .padding()
    .environment(\.layoutDirection, .rightToLeft)
}

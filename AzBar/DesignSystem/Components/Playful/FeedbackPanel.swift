import SwiftUI

/// Bottom panel shown after a graded answer: green «آفرین!»-family title + «+۲ امتیاز», or red «نادرست» +
/// «پاسخ درست:» and the answer in the poem font. A chunky «ادامه» button unless an accessory is supplied
/// (then the accessory, e.g. a RatingBar, replaces it). Posts an AccessibilityNotification announcement.
struct FeedbackPanel<Accessory: View>: View {
    enum Kind: Equatable {
        case correct(message: String)
        case incorrect(answer: String)
    }

    let kind: Kind
    var xp: Int = 0
    let onContinue: () -> Void
    @ViewBuilder var accessory: Accessory

    @Environment(AppSettings.self) private var settings: AppSettings?
    @Environment(\.colorScheme) private var colorScheme

    init(kind: Kind, xp: Int = 0, onContinue: @escaping () -> Void, @ViewBuilder accessory: () -> Accessory) {
        self.kind = kind
        self.xp = xp
        self.onContinue = onContinue
        self.accessory = accessory()
    }

    private var isCorrect: Bool {
        if case .correct = kind { true } else { false }
    }

    private var tint: Color { isCorrect ? Theme.Playful.correct : Theme.Playful.wrong }
    private var textTint: Color { tint.mix(with: colorScheme == .dark ? .white : .black, by: colorScheme == .dark ? 0.2 : 0.3) }
    private var hasAccessory: Bool { Accessory.self != EmptyView.self }

    private var title: String {
        switch kind {
        case .correct(let message): message
        case .incorrect: "نادرست"
        }
    }

    private var announcement: String {
        switch kind {
        case .correct(let message):
            xp > 0 ? "\(message) به‌علاوهٔ \(xp.fa) امتیاز" : message
        case .incorrect(let answer):
            "نادرست. پاسخ درست: \(answer)"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.s) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.app(.title3, weight: .bold))
                Spacer(minLength: 0)
                if isCorrect, xp > 0 {
                    Text("+\(xp.fa) امتیاز")
                        .font(.app(.subheadline, weight: .bold))
                        .padding(.horizontal, Theme.Spacing.m)
                        .padding(.vertical, Theme.Spacing.xs)
                        .background(Theme.Playful.xp.opacity(0.18), in: .capsule)
                        .foregroundStyle(Theme.Playful.xp.mix(with: colorScheme == .dark ? .white : .black, by: 0.2))
                }
            }
            .foregroundStyle(textTint)

            if case .incorrect(let answer) = kind {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("پاسخ درست:")
                        .font(.app(.footnote, weight: .semibold))
                    Text(verbatim: answer)
                        .font(.poem(settings?.poemFont ?? .naskh, size: CGFloat(settings?.poemFontSize ?? 22)))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(textTint)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if hasAccessory {
                accessory
            } else {
                Button("ادامه", action: onContinue)
                    .buttonStyle(.chunky(tint))
            }
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            Rectangle()
                .fill(tint.opacity(colorScheme == .dark ? 0.22 : 0.14))
                .background(.background)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: Theme.Radius.card, topTrailingRadius: Theme.Radius.card))
                .ignoresSafeArea(edges: .bottom)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .contain)
        .onAppear {
            AccessibilityNotification.Announcement(announcement).post()
        }
    }
}

extension FeedbackPanel where Accessory == EmptyView {
    init(kind: Kind, xp: Int = 0, onContinue: @escaping () -> Void) {
        self.init(kind: kind, xp: xp, onContinue: onContinue) { EmptyView() }
    }
}

#Preview("Correct") {
    FeedbackPanel(kind: .correct(message: "آفرین!"), xp: 2) {}
        .persianRoot()
}

#Preview("Incorrect") {
    FeedbackPanel(kind: .incorrect(answer: "دل می‌رود ز دستم صاحب‌دلان خدا را")) {}
        .persianRoot()
}

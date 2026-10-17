import SwiftUI

struct LearnSummaryView: View {
    let learnedCount: Int
    let isPoemComplete: Bool
    let poemTitle: String
    let onContinue: () -> Void
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer(minLength: Theme.Spacing.xl)
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 84))
                .foregroundStyle(.tint)
                .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : appeared)
                .accessibilityHidden(true)
            VStack(spacing: Theme.Spacing.s) {
                Text("آفرین!")
                    .font(.app(.largeTitle))
                    .accessibilityAddTraits(.isHeader)
                if learnedCount > 0 {
                    Text("\(learnedCount.fa) بیت تازه از بر شد")
                        .font(.app(.title3))
                }
                if isPoemComplete {
                    Text("همهٔ بیت‌های این شعر را آموختید")
                        .font(.app(.body))
                        .foregroundStyle(.secondary)
                } else {
                    Text("بیت‌ها فردا در بخش مرور به شما یادآوری می‌شوند.")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, Theme.Spacing.xl)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SessionActionBar {
                VStack(spacing: Theme.Spacing.s) {
                    if !isPoemComplete {
                        SessionPrimaryButton(title: "ادامهٔ حفظ", action: onContinue)
                    }
                    Button(action: onFinish) {
                        Text("پایان")
                            .font(.app(.headline))
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                }
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .task { appeared = true }
    }
}

#Preview("Batch done") {
    PreviewContainer {
        LearnSummaryView(learnedCount: 2, isPoemComplete: false, poemTitle: "غزل شمارهٔ ۱", onContinue: {}, onFinish: {})
    }
}

#Preview("Poem complete") {
    PreviewContainer {
        LearnSummaryView(learnedCount: 1, isPoemComplete: true, poemTitle: "غزل شمارهٔ ۱", onContinue: {}, onFinish: {})
    }
}

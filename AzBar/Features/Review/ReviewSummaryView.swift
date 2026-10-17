import SwiftUI

struct ReviewSummaryView: View {
    let counts: [Rating: Int]
    let streak: Int
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var total: Int { counts.values.reduce(0, +) }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.xl) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 76))
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : appeared)
                    .accessibilityHidden(true)
                VStack(spacing: Theme.Spacing.s) {
                    Text("مرور امروز تمام شد")
                        .font(.app(.title))
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(total.fa) بیت مرور شد")
                        .font(.app(.body))
                        .foregroundStyle(.secondary)
                    if streak > 0 {
                        Text("\(streak.fa) روز پیاپی")
                            .font(.app(.headline))
                            .foregroundStyle(.orange)
                    }
                }
                VStack(spacing: 0) {
                    ForEach(Array(Rating.allCases.enumerated()), id: \.element) { index, rating in
                        if index > 0 { Divider() }
                        HStack {
                            Circle().fill(Theme.color(for: rating)).frame(width: 10, height: 10)
                                .accessibilityHidden(true)
                            Text(Theme.title(for: rating))
                            Spacer()
                            Text((counts[rating] ?? 0).fa)
                                .foregroundStyle(.secondary)
                        }
                        .font(.app(.body))
                        .padding(.vertical, Theme.Spacing.m)
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, Theme.Spacing.l)
                .background(.background.secondary, in: .rect(cornerRadius: Theme.Radius.card))
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SessionActionBar { SessionPrimaryButton(title: "پایان", action: onDone) }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .task { appeared = true }
    }
}

#Preview {
    PreviewContainer {
        ReviewSummaryView(counts: [.again: 1, .hard: 2, .good: 6, .easy: 3], streak: 5, onDone: {})
    }
}

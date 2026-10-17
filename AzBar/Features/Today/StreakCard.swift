import SwiftUI

/// Streak + due count + review CTA, rendered as the content of one List row.
struct StreakCard: View {
    let streak: Int
    let dueCount: Int
    let hasActivityToday: Bool
    let onStartReview: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: Theme.Spacing.l) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(hasActivityToday || streak > 0 ? Color.orange : Color.secondary)
                    .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? 0 : streak)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.fa) روز پیاپی")
                        .font(.app(.title2))
                        .contentTransition(.numericText())
                    Text(dueCount > 0 ? "\(dueCount.fa) بیت برای مرور" : "امروز مروری ندارید")
                        .font(.app(.subheadline))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)

            Button(action: onStartReview) {
                Text("شروع مرور")
                    .font(.app(.headline))
                    .frame(maxWidth: .infinity, minHeight: 36)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .disabled(dueCount == 0)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    List {
        Section { StreakCard(streak: 7, dueCount: 12, hasActivityToday: true, onStartReview: {}) }
        Section { StreakCard(streak: 0, dueCount: 0, hasActivityToday: false, onStartReview: {}) }
    }
    .environment(\.layoutDirection, .rightToLeft)
}

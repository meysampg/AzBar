import SwiftUI

struct ReviewSummaryView: View {
    let counts: [Rating: Int]
    let streak: Int
    var xp: Int = 0
    var reward: SessionReward?
    let onDone: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var confetti = 0
    @State private var isCelebrating = false
    @State private var celebrationsDone = false

    private var celebrations: [Celebration] { reward?.celebrations ?? [] }
    private var needsCelebration: Bool { !celebrations.isEmpty && !celebrationsDone }

    private var total: Int { counts.values.reduce(0, +) }

    var body: some View {
        ZStack {
            summary
            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
            if isCelebrating {
                CelebrationSequenceView(celebrations: celebrations) {
                    withAnimation(reduceMotion ? nil : .smooth) {
                        celebrationsDone = true
                        isCelebrating = false
                    }
                    onDone()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemBackground))
                .transition(.opacity)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isCelebrating {
                SessionActionBar {
                    if needsCelebration {
                        Button("ادامه") {
                            withAnimation(reduceMotion ? nil : .smooth) { isCelebrating = true }
                        }
                        .buttonStyle(.chunky(.blue))
                    } else {
                        Button("پایان", action: onDone)
                            .buttonStyle(.chunky(.blue))
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .task {
            appeared = true
            confetti += 1
            app.sounds.play(.lessonComplete)
        }
    }

    private var summary: some View {
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
                    HStack(spacing: Theme.Spacing.m) {
                        StatTile(title: "امتیاز", value: "+\(xp.fa)", systemImage: "bolt.fill", tint: Theme.Playful.xp)
                        StatTile(title: "مرورشده", value: total.fa, systemImage: "rectangle.stack.fill", tint: .blue)
                    }
                    .padding(.top, Theme.Spacing.s)
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
    }
}

#Preview {
    PreviewContainer {
        ReviewSummaryView(counts: [.again: 1, .hard: 2, .good: 6, .easy: 3], streak: 5, xp: 22, onDone: {})
    }
}

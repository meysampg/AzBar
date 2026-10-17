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
                .background(Theme.Palette.paper.ignoresSafeArea())
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
                        .buttonStyle(.azPrimary)
                    } else {
                        Button("پایان", action: onDone)
                            .buttonStyle(.azPrimary)
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
                AzMedallion(diameter: 96, fill: Theme.Palette.teal, edge: Theme.Palette.tealDeep) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : appeared)
                }
                .frame(width: 96, height: 100)
                .accessibilityHidden(true)
                VStack(spacing: Theme.Spacing.s) {
                    Text("مرور امروز تمام شد")
                        .font(.azDisplay)
                        .foregroundStyle(Theme.Palette.ink)
                        .multilineTextAlignment(.center)
                        .accessibilityAddTraits(.isHeader)
                    Text("\(total.fa) بیت مرور شد")
                        .font(.azBody)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                HStack(spacing: Theme.Spacing.m) {
                    StatTile(title: "امتیاز", value: "+\(xp.fa)", systemImage: "bolt.fill", tint: Theme.Palette.gold)
                    StatTile(title: "مرورشده", value: total.fa, systemImage: "rectangle.stack.fill", tint: Theme.Palette.teal)
                }
                ratingChips
                if streak > 0 {
                    HStack(spacing: Theme.Spacing.m) {
                        StreakFlame(streak: streak, isActiveToday: true, size: 30)
                            .accessibilityHidden(true)
                        Text("\(streak.fa) روز پیاپی")
                            .font(.azHeadline)
                            .foregroundStyle(Theme.Palette.ink)
                        Spacer(minLength: 0)
                    }
                    .azCard()
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(Theme.Layout.margin)
            .frame(maxWidth: Theme.Layout.sessionWidth)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .azScreenBackground()
    }

    private var ratingChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: Theme.Spacing.s)], spacing: Theme.Spacing.s) {
            ForEach(Rating.allCases, id: \.self) { rating in
                AzChip("\(Theme.title(for: rating)) \((counts[rating] ?? 0).fa)", tone: AzTone(rating))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Theme.title(for: rating))
                    .accessibilityValue((counts[rating] ?? 0).fa)
            }
        }
    }
}

#Preview {
    PreviewContainer {
        ReviewSummaryView(counts: [.again: 1, .hard: 2, .good: 6, .easy: 3], streak: 5, xp: 22, onDone: {})
    }
}

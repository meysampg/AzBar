import SwiftUI

/// End-of-session screen: result, XP, accuracy, streak, daily goal, level and new badges.
struct LessonCompleteView: View {
    let kind: LessonKind
    let passed: Bool
    let reward: SessionReward?
    let xp: Int
    let learnedCount: Int
    let isPoemComplete: Bool
    let hasNextLesson: Bool
    let onNext: () -> Void
    let onFinish: () -> Void

    @Environment(AppModel.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var confetti = 0
    @State private var isCelebrating = false
    @State private var celebrationsDone = false

    private var celebrations: [Celebration] { reward?.celebrations ?? [] }
    private var needsCelebration: Bool { !celebrations.isEmpty && !celebrationsDone }

    private var heading: String {
        switch kind {
        case .lesson: "درس تمام شد!"
        case .practice: "تمرین تمام شد!"
        case .challenge: passed ? "آزمون را گذراندید!" : "این بار نشد"
        }
    }

    private var heroSymbol: String {
        if kind == .challenge { return passed ? "trophy.fill" : "arrow.counterclockwise" }
        return "checkmark"
    }

    private var hero: some View {
        let failed = !passed
        let gold = kind == .challenge && passed
        return AzMedallion(
            diameter: 120,
            fill: failed ? Theme.Palette.danger : (gold ? Theme.Palette.gold : Theme.Palette.teal),
            rim: (failed || gold) ? nil : Theme.Palette.gold,
            rimWidth: 5,
            edge: failed ? Theme.Palette.dangerDeep : (gold ? Theme.Palette.goldEdge : Theme.Palette.tealDeep)
        ) {
            Image(systemName: heroSymbol)
                .font(.system(size: 52, weight: .bold))
                .foregroundStyle(gold ? Theme.Palette.ink : Color.white)
                .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? false : appeared)
        }
        .padding(.bottom, Theme.Spacing.xs)
        .accessibilityHidden(true)
    }

    private var levelUp: Int? {
        for case .levelUp(let level) in celebrations { return level }
        return nil
    }

    private var newBadges: [BadgeID] {
        celebrations.compactMap { if case .badge(let id) = $0 { id } else { nil } }
    }

    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    hero
                    titleBlock
                    tiles
                    statusCard
                    if levelUp != nil || !newBadges.isEmpty { rewardsRow }
                }
                .padding(.horizontal, Theme.Spacing.xl)
                .padding(.vertical, Theme.Spacing.xl)
                .frame(maxWidth: Theme.Layout.sessionWidth)
                .frame(maxWidth: .infinity)
            }
            .scrollBounceBehavior(.basedOnSize)
            ConfettiView(trigger: confetti)
                .ignoresSafeArea()
            if isCelebrating {
                CelebrationSequenceView(celebrations: celebrations) {
                    withAnimation(reduceMotion ? nil : .smooth) {
                        celebrationsDone = true
                        isCelebrating = false
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Palette.paper)
                .transition(.opacity)
            }
        }
        .azScreenBackground()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !isCelebrating { actions }
        }
        .sensoryFeedback(passed ? .success : .warning, trigger: appeared)
        .task {
            appeared = true
            if passed { confetti += 1 }
            app.sounds.play(.lessonComplete)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text(heading)
                .font(.azDisplay)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            if kind == .challenge && !passed {
                Text("دوباره تلاش کنید")
                    .font(.azBody)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
            if learnedCount > 0 {
                Text("\(learnedCount.fa) بیت تازه از بر شد")
                    .font(.app(.title3))
                    .foregroundStyle(Theme.Palette.ink)
            }
            if isPoemComplete {
                Text("همهٔ بیت‌های این شعر را آموختید")
                    .font(.azBody)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            } else if kind == .lesson && learnedCount > 0 {
                Text("بیت‌ها فردا در بخش مرور به شما یادآوری می‌شوند.")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            }
        }
        .multilineTextAlignment(.center)
    }

    private var tiles: some View {
        HStack(spacing: Theme.Spacing.m) {
            StatTile(title: "امتیاز", value: "+\(xp.fa)", systemImage: "bolt.fill", tint: Theme.Palette.gold)
            if let accuracy = reward?.accuracy {
                StatTile(title: "دقت", value: "\(Int((accuracy * 100).rounded()).fa)٪",
                         systemImage: "target", tint: Theme.Palette.success)
            }
            if learnedCount > 0 {
                StatTile(title: "بیت تازه", value: learnedCount.fa, systemImage: "text.book.closed", tint: Theme.Palette.teal)
            }
        }
    }

    private var statusCard: some View {
        let streak = app.progress.currentStreak()
        let goal = app.gamification.dailyGoal
        let today = app.gamification.todayXP
        let info = app.gamification.levelInfo
        return VStack(spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.l) {
                StreakFlame(streak: streak, isActiveToday: streak > 0, size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(streak.fa) روز پیاپی").font(.azHeadline).foregroundStyle(Theme.Palette.ink)
                    Text("سطح \(info.level.fa) · \(LevelText.title(level: info.level))")
                        .font(.azMeta)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                VStack(spacing: 2) {
                    DailyGoalRing(xp: today, goal: goal, size: 60)
                    Text("هدف روزانه").font(.azCaption).foregroundStyle(Theme.Palette.inkSecondary)
                }
            }
            AzProgressBar(value: info.fraction, tint: Theme.Palette.gold, height: 10, label: "پیشرفت سطح")
        }
        .azCard()
        .accessibilityElement(children: .contain)
    }

    private var rewardsRow: some View {
        VStack(spacing: Theme.Spacing.m) {
            if let level = levelUp {
                Label("به سطح \(level.fa) رسیدید", systemImage: "star.circle.fill")
                    .font(.azHeadline)
                    .foregroundStyle(Theme.Palette.goldDeep)
            }
            if !newBadges.isEmpty {
                HStack(spacing: Theme.Spacing.l) {
                    ForEach(newBadges, id: \.self) { badge in
                        VStack(spacing: Theme.Spacing.xs) {
                            BadgeMedal(badge: badge, unlocked: true, size: 56)
                            Text(badge.title).font(.azCaption).foregroundStyle(Theme.Palette.ink)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actions: some View {
        SessionActionBar {
            VStack(spacing: Theme.Spacing.s) {
                if needsCelebration {
                    Button("ادامه") {
                        withAnimation(reduceMotion ? nil : .smooth) { isCelebrating = true }
                    }
                    .buttonStyle(.azPrimary)
                } else {
                    if hasNextLesson {
                        Button("درس بعدی", action: onNext)
                            .buttonStyle(.azPrimary)
                        Button("پایان", action: onFinish)
                            .buttonStyle(.azSecondary)
                    } else {
                        Button("پایان", action: onFinish)
                            .buttonStyle(.azPrimary)
                    }
                }
            }
        }
    }
}

#Preview("Lesson") {
    PreviewContainer {
        LessonCompleteView(kind: .lesson, passed: true,
                           reward: SessionReward(xpEarned: 28, accuracy: 0.83, celebrations: []),
                           xp: 28, learnedCount: 2, isPoemComplete: false, hasNextLesson: true,
                           onNext: {}, onFinish: {})
    }
}

#Preview("Challenge failed") {
    PreviewContainer {
        LessonCompleteView(kind: .challenge, passed: false,
                           reward: SessionReward(xpEarned: 6, accuracy: 0.5, celebrations: []),
                           xp: 6, learnedCount: 0, isPoemComplete: false, hasNextLesson: false,
                           onNext: {}, onFinish: {})
    }
}

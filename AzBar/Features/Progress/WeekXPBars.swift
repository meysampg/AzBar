import SwiftUI

/// Seven capsules, oldest first (so today sits at the visual end of the time axis, per RTL rule 6).
struct WeekXPBars: View {
    let week: [(day: DayKey, xp: Int)]
    let goal: Int

    private let barHeight: CGFloat = 110

    private var maxValue: Double { Double(max(goal, week.map(\.xp).max() ?? 0, 1)) }

    var body: some View {
        HStack(alignment: .bottom, spacing: Theme.Spacing.s) {
            ForEach(Array(week.enumerated()), id: \.offset) { i, entry in
                let isToday = i == week.count - 1
                VStack(spacing: Theme.Spacing.xs) {
                    Text(entry.xp.fa)
                        .font(.azCaption)
                        .foregroundStyle(Theme.Palette.inkSecondary)
                    ZStack(alignment: .bottom) {
                        Capsule().fill(Theme.Palette.track)
                        Capsule()
                            .fill(entry.xp >= goal ? Theme.Palette.teal : Theme.Palette.gold)
                            .frame(height: max(entry.xp > 0 ? 8 : 0, barHeight * Double(entry.xp) / maxValue))
                    }
                    .frame(height: barHeight)
                    Text(Self.weekdayInitial(entry.day))
                        .font(isToday ? .app(.caption, weight: .bold) : .azCaption)
                        .foregroundStyle(isToday ? Theme.Palette.teal : Theme.Palette.inkSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.xs)
                .background {
                    if isToday { RoundedRectangle(cornerRadius: Theme.Radius.token, style: .continuous).fill(Theme.Palette.goldSoft) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Self.weekdayName(entry.day))
                .accessibilityValue("\(entry.xp.fa) امتیاز")
            }
        }
        .overlay(alignment: .bottom) {
            // Dashed goal line, measured from the bar baseline (above the weekday label).
            GeometryReader { geo in
                let y = geo.size.height - 22 - barHeight * min(1, Double(goal) / maxValue)
                Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: geo.size.width, y: y))
                }
                .stroke(Theme.Palette.teal.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }

    private static func persianDate(_ day: DayKey) -> Date {
        day.startDate(in: DayKey.gregorian()).addingTimeInterval(12 * 3600)
    }

    private static func weekdayInitial(_ day: DayKey) -> String {
        format(day, "EEEEE")
    }

    private static func weekdayName(_ day: DayKey) -> String {
        format(day, "EEEE")
    }

    private static func format(_ day: DayKey, _ pattern: String) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .persian)
        f.locale = Locale(identifier: "fa_IR")
        f.dateFormat = pattern
        return f.string(from: persianDate(day))
    }
}

#Preview {
    let cal = DayKey.gregorian()
    let end = DayKey(.now, calendar: cal)
    let xp = [12, 0, 30, 25, 8, 40, 14]
    WeekXPBars(week: (0..<7).map { (end.adding(days: $0 - 6, calendar: cal), xp[$0]) }, goal: 20)
        .padding()
        .persianRoot()
}

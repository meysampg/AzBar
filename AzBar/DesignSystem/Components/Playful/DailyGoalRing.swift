import SwiftUI

/// ProgressRing-like orange ring (lineWidth 9), center "\(xp.fa)/\(goal.fa)", checkmark once met.
/// Clockwise from 12 o'clock in every layout direction.
struct DailyGoalRing: View {
    var xp: Int
    var goal: Int
    var size: CGFloat = 64

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var met: Bool { goal > 0 && xp >= goal }
    private var lineWidth: CGFloat { 9 }

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: DailyGoal.progress(xp: xp, goal: goal))
                .stroke(met ? Theme.Playful.correct : Theme.Playful.xp,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(reduceMotion ? nil : .spring(duration: 0.6), value: xp)
            if met {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.34, weight: .heavy))
                    .foregroundStyle(Theme.Playful.correct)
            } else {
                Text("\(xp.fa)/\(goal.fa)")
                    .font(.app(.caption2, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .padding(.horizontal, lineWidth + 2)
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("هدف روزانه")
        .accessibilityValue(met ? "کامل شد، \(xp.fa) امتیاز" : "\(xp.fa) از \(goal.fa) امتیاز")
    }
}

#Preview {
    HStack(spacing: 20) {
        DailyGoalRing(xp: 8, goal: 20)
        DailyGoalRing(xp: 20, goal: 20)
    }
    .padding()
    .persianRoot()
}

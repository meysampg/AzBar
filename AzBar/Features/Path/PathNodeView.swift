import SwiftUI

/// One node of the learning path: a chunky circle, an optional caption and a details popover.
struct PathNodeView: View {
    let node: PathNode
    /// First and last memorizable position (1-based) the node covers; lessons only.
    let beytRange: ClosedRange<Int>?
    /// A current lesson that was already started («ادامه»).
    let isPartial: Bool
    let onStart: (LearnMode) -> Void

    @State private var showDetails = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var symbol: String {
        switch (node.state, node.kind) {
        case (.locked, _): "lock.fill"
        case (.current, _): "star.fill"
        case (.available, .challenge): "trophy.fill"
        case (.available, _): "dumbbell.fill"
        case (.completed, _): "checkmark"
        case (.mastered, _): "crown.fill"
        }
    }

    private var tint: Color {
        switch (node.state, node.kind) {
        case (.locked, _): Theme.Playful.locked
        case (.current, _): Theme.Playful.correct
        case (.available, .challenge): .purple
        case (.available, _): .blue
        case (.completed, _), (.mastered, _): Theme.Playful.gold
        }
    }

    private var caption: String {
        switch node.kind {
        case .lesson:
            if let n = node.lessonNumber, let r = beytRange {
                "درس \(n.fa) · بیت \(r.lowerBound.fa)–\(r.upperBound.fa)"
            } else {
                "درس \(node.lessonNumber?.fa ?? "")"
            }
        case .review: "تمرین"
        case .challenge: "آزمون کل غزل"
        }
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.s) {
            if node.state == .current {
                Text(isPartial ? "ادامه" : "شروع")
                    .font(.app(.footnote, weight: .bold))
                    .foregroundStyle(Theme.Playful.correct)
                    .padding(.horizontal, Theme.Spacing.m)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(.background, in: .rect(cornerRadius: Theme.Radius.small))
                    .overlay { RoundedRectangle(cornerRadius: Theme.Radius.small).stroke(.quaternary, lineWidth: 2) }
                    .offset(y: pulse && !reduceMotion ? -4 : 0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulse)
                    .accessibilityHidden(true)
            }
            Button(action: tapped) {
                Image(systemName: symbol)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(ChunkyCircleButtonStyle(tint: tint))
            .background {
                if node.state == .current {
                    Circle()
                        .stroke(tint.opacity(0.4), lineWidth: 4)
                        .scaleEffect(pulse && !reduceMotion ? 1.35 : 1.05)
                        .opacity(pulse && !reduceMotion ? 0 : 1)
                        .animation(reduceMotion ? nil : .easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                        .frame(width: 72, height: 72)
                }
            }
            .popover(isPresented: $showDetails) { details }
            Text(caption)
                .font(.app(.caption))
                .foregroundStyle(node.state == .locked ? .tertiary : .secondary)
        }
        .onAppear { pulse = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(caption)
        .accessibilityValue(stateText)
        .accessibilityAddTraits(.isButton)
    }

    private var stateText: String {
        switch node.state {
        case .locked: "قفل"
        case .available: "آماده"
        case .current: isPartial ? "ادامه" : "شروع"
        case .completed: "تمام‌شده"
        case .mastered: "تسلط کامل"
        }
    }

    private func tapped() {
        switch (node.state, node.kind) {
        case (.current, _):
            onStart(.lesson(nodeId: node.id, coupletIndices: node.coupletIndices))
        case (.available, .challenge):
            onStart(.challenge)
        case (.available, _):
            onStart(.practice(nodeId: node.id, coupletIndices: node.coupletIndices))
        case (.locked, _), (.completed, _), (.mastered, _):
            showDetails = true
        }
    }

    @ViewBuilder
    private var details: some View {
        VStack(spacing: Theme.Spacing.m) {
            if node.state == .locked {
                Text("این درس هنوز قفل است").font(.app(.headline))
                Text("درس‌های پیشین را تمام کنید")
                    .font(.app(.subheadline))
                    .foregroundStyle(.secondary)
            } else {
                Text(node.kind == .lesson ? "درس \(node.lessonNumber?.fa ?? "")" : caption)
                    .font(.app(.headline))
                Button {
                    showDetails = false
                    if node.kind == .challenge {
                        onStart(.challenge)
                    } else {
                        onStart(.practice(nodeId: "\(node.id)-p", coupletIndices: node.coupletIndices))
                    }
                } label: {
                    Text(node.kind == .challenge ? "آزمون دوباره" : "تمرین دوباره")
                }
                .buttonStyle(.chunky(.blue))
            }
        }
        .padding(Theme.Spacing.l)
        .frame(minWidth: 240)
        .presentationCompactAdaptation(.popover)
        .persianRoot()
    }
}

#Preview {
    VStack(spacing: 24) {
        PathNodeView(node: PathNode(id: "L0", kind: .lesson, ordinal: 0, coupletIndices: [0, 1], lessonNumber: 1, state: .current),
                     beytRange: 1...2, isPartial: false, onStart: { _ in })
        PathNodeView(node: PathNode(id: "L2", kind: .lesson, ordinal: 1, coupletIndices: [2, 3], lessonNumber: 2, state: .locked),
                     beytRange: 3...4, isPartial: false, onStart: { _ in })
        PathNodeView(node: PathNode(id: "C", kind: .challenge, ordinal: 2, coupletIndices: [0], lessonNumber: nil, state: .mastered),
                     beytRange: nil, isPartial: false, onStart: { _ in })
    }
    .persianRoot()
}

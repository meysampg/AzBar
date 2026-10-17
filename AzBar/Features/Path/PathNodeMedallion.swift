import SwiftUI

/// One node of the learning path: a medallion button with a details popover.
/// Positioning is done by `PathMapView`; this view only draws the node and handles taps.
struct PathNodeMedallion: View {
    let node: PathNode
    let diameter: CGFloat
    /// Label text shared with accessibility.
    let caption: String
    /// A current lesson that was already started («ادامه»).
    let isPartial: Bool
    let onStart: (LearnMode) -> Void

    @State private var showDetails = false
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private struct Look {
        var shape: AzMedallionKind
        var fill: Color
        var rim: Color?
        var rimWidth: CGFloat
        var edge: Color
        var symbol: String
        var symbolColor: Color
        var bold: Bool
    }

    private var look: Look {
        let square = node.kind == .review
        let shape: AzMedallionKind = square ? .roundedSquare : .circle
        let locked = Look(shape: shape, fill: Theme.Palette.lockedFill, rim: Theme.Palette.sand, rimWidth: 3,
                          edge: Theme.Palette.sand, symbol: node.kind == .challenge ? "trophy.fill" : "lock.fill",
                          symbolColor: Theme.Palette.sandDeep, bold: false)
        switch (node.state, node.kind) {
        case (.locked, _):
            return locked
        case (.mastered, _):
            return Look(shape: shape, fill: Theme.Palette.gold, rim: Theme.Palette.goldDeep, rimWidth: 3,
                        edge: Theme.Palette.goldEdge, symbol: "crown.fill", symbolColor: Theme.Palette.ink, bold: false)
        case (.current, _):
            return Look(shape: .circle, fill: Theme.Palette.teal, rim: Theme.Palette.gold, rimWidth: 5,
                        edge: Theme.Palette.tealDeep, symbol: "star.fill", symbolColor: .white, bold: false)
        case (.completed, .lesson):
            return Look(shape: .circle, fill: Theme.Palette.teal, rim: nil, rimWidth: 0,
                        edge: Theme.Palette.tealDeep, symbol: "checkmark", symbolColor: .white, bold: true)
        case (.completed, .review):
            return Look(shape: .roundedSquare, fill: Theme.Palette.teal, rim: nil, rimWidth: 0,
                        edge: Theme.Palette.tealDeep, symbol: "arrow.triangle.2.circlepath", symbolColor: .white, bold: false)
        case (.completed, .challenge):
            return Look(shape: .circle, fill: Theme.Palette.teal, rim: Theme.Palette.gold, rimWidth: 3,
                        edge: Theme.Palette.tealDeep, symbol: "trophy.fill", symbolColor: .white, bold: false)
        case (.available, .review):
            return Look(shape: .roundedSquare, fill: Theme.Palette.card, rim: Theme.Palette.teal, rimWidth: 3,
                        edge: Theme.Palette.whiteEdge, symbol: "arrow.triangle.2.circlepath",
                        symbolColor: Theme.Palette.teal, bold: false)
        case (.available, .challenge):
            return Look(shape: .circle, fill: Theme.Palette.gold, rim: Theme.Palette.goldDeep, rimWidth: 3,
                        edge: Theme.Palette.goldEdge, symbol: "trophy.fill", symbolColor: Theme.Palette.ink, bold: false)
        case (.available, .lesson):
            // Lessons are never "available" (they are current/completed/locked); keep a sane fallback.
            return Look(shape: .circle, fill: Theme.Palette.card, rim: Theme.Palette.teal, rimWidth: 3,
                        edge: Theme.Palette.whiteEdge, symbol: "star.fill", symbolColor: Theme.Palette.teal, bold: false)
        }
    }

    var body: some View {
        let look = look
        Button(action: tapped) {
            AzMedallion(shape: look.shape, diameter: diameter, fill: look.fill,
                        rim: look.rim, rimWidth: look.rimWidth, edge: look.edge) {
                Image(systemName: look.symbol)
                    .font(.system(size: diameter * 0.42, weight: look.bold ? .heavy : .semibold))
                    .foregroundStyle(look.symbolColor)
            }
        }
        .buttonStyle(AzMedallionButtonStyle())
        .background {
            if node.state == .current {
                // Paper gap ring between the medallion and the pulse.
                Circle()
                    .strokeBorder(Theme.Palette.paper, lineWidth: 4)
                    .frame(width: diameter + 8, height: diameter + 8)
                Circle()
                    .stroke(Theme.Palette.gold, lineWidth: 3)
                    .frame(width: diameter, height: diameter)
                    .scaleEffect(pulse && !reduceMotion ? 1.35 : 1.0)
                    .opacity(reduceMotion ? 0.5 : (pulse ? 0 : 0.8))
                    .animation(reduceMotion ? nil : .easeOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
            }
        }
        .popover(isPresented: $showDetails) { details }
        .onAppear { pulse = true }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue(stateText)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tapped() }
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
                Text("این درس هنوز قفل است").font(.azHeadline).foregroundStyle(Theme.Palette.ink)
                Text("درس‌های پیشین را تمام کنید")
                    .font(.azMeta)
                    .foregroundStyle(Theme.Palette.inkSecondary)
            } else {
                Text(verbatim: caption).font(.azHeadline).foregroundStyle(Theme.Palette.ink)
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
                .buttonStyle(.azPrimary)
            }
        }
        .padding(Theme.Spacing.l)
        .frame(minWidth: 240)
        .background(Theme.Palette.paper)
        .presentationCompactAdaptation(.popover)
        .persianRoot()
    }
}

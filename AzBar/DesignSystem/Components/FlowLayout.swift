import SwiftUI

/// Wrapping layout for word tokens (poem lines).
///
/// Relies on SwiftUI's automatic RTL mirroring of Layout placement: positions are computed in
/// leading-origin space, so the first subview sits on the reading-start side (right in RTL).
/// Rows can be aligned to the leading edge, the centre or the trailing edge.
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    var rowAlignment: HorizontalAlignment = .center

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(for subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var result: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let extra = current.indices.isEmpty ? 0 : horizontalSpacing
            if !current.indices.isEmpty, current.width + extra + size.width > maxWidth {
                result.append(current)
                current = Row()
            }
            let spacing = current.indices.isEmpty ? 0 : horizontalSpacing
            current.indices.append(index)
            current.width += spacing + size.width
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty { result.append(current) }
        return result
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = rows(for: subviews, maxWidth: maxWidth)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        return CGSize(width: width.isFinite ? width : 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = rows(for: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            let startOffset: CGFloat
            switch rowAlignment {
            case .leading: startOffset = 0
            case .trailing: startOffset = bounds.width - row.width
            default: startOffset = (bounds.width - row.width) / 2
            }
            var offset = startOffset
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                let x = bounds.minX + offset
                subviews[index].place(
                    at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                offset += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }
}

#Preview {
    FlowLayout(horizontalSpacing: 8, verticalSpacing: 8, rowAlignment: .center) {
        ForEach(1...14, id: \.self) { i in
            Text("\(i.fa)")
                .padding(.horizontal, 8)
                .background(.quaternary, in: .capsule)
        }
    }
    .padding()
    .persianRoot()
}

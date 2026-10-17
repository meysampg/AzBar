import SwiftUI

struct MesraText: View {
    let text: String
    let font: PoemFont
    let size: CGFloat
    var alignment: TextAlignment = .center

    var body: some View {
        Text(verbatim: text)
            .font(.poem(font, size: size))
            .lineSpacing(font.lineSpacing(size))
            .multilineTextAlignment(alignment)
            .padding(.vertical, font.verticalPadding(size))
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    MesraText(text: "اَلا یا اَیُّهَا السّاقی اَدِرْ کَأساً و ناوِلْها", font: .naskh, size: 22)
        .environment(\.layoutDirection, .rightToLeft)
}

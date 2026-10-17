// PLACEHOLDER (WP0): WP3 overwrites this file, keeping `init(poemId:poetId:)`
import SwiftUI

struct ReaderView: View {
    let poemId: PoemID
    let poetId: PoetID

    var body: some View {
        ContentUnavailableView("خواندن شعر", systemImage: "text.book.closed")
            .navigationTitle("شعر")
            .navigationBarTitleDisplayMode(.inline)
    }
}

// STUB (P-D): implement, keep signatures
import SwiftUI

/// The learning path of one poem (Duolingo-style node list).
struct PoemPathView: View {
    let poemId: PoemID
    let poetId: PoetID

    var body: some View {
        Text("مسیر یادگیری")
            .navigationTitle("مسیر یادگیری")
            .navigationBarTitleDisplayMode(.inline)
    }
}

import SwiftUI

enum PreviewFixtures {
    /// Hafez ghazal 1 (first three beyts).
    static let samplePoem = Poem(
        id: 2130, poetId: 2, categoryId: 24,
        title: "غزل شمارهٔ ۱", fullTitle: "حافظ » غزلیات » غزل شمارهٔ ۱",
        urlSlug: "sh1", fullUrl: "/hafez/ghazal/sh1",
        summary: "در این شعر حافظ از عشق و چالش\u{200C}های آن سخن می\u{200C}گوید.",
        couplets: [
            Couplet(index: 0, kind: .beyt, verses: [
                Verse(id: 3794588, order: 1, position: 0, text: "اَلا یا اَیُّهَا السّاقی اَدِرْ کَأساً و ناوِلْها"),
                Verse(id: 3794590, order: 2, position: 1, text: "که عشق آسان نمود اوّل ولی افتاد مشکل\u{200C}ها"),
            ], summary: "هان ای ساقی جام شراب را به گردش درآور و به من بده؛ چرا که عشق در ابتدا آسان جلوه کرد اما در پایان دشوار شد."),
            Couplet(index: 1, kind: .beyt, verses: [
                Verse(id: 3794586, order: 3, position: 0, text: "به بویِ نافه\u{200C}ای کآخِر صبا زان طُرّه بُگشاید"),
                Verse(id: 3794587, order: 4, position: 1, text: "ز تابِ جَعدِ مشکینش چه خون افتاد در دل\u{200C}ها"),
            ], summary: "به امید بوی مشک، که صبا از آن زلف می\u{200C}گشاید، از پیچ و تاب موی مشک\u{200C}بوی او چه خون\u{200C}ها در دل\u{200C}ها افتاد."),
            Couplet(index: 2, kind: .beyt, verses: [
                Verse(id: 3794584, order: 5, position: 0, text: "مرا در منزلِ جانان چه امنِ عیش، چون هر دَم"),
                Verse(id: 3794585, order: 6, position: 1, text: "جَرَس فریاد می\u{200C}دارد که بَربندید مَحمِل\u{200C}ها"),
            ], summary: nil),
        ],
        recitations: [
            Recitation(id: 2840, artist: "فریدون فرح\u{200C}اندوز",
                       mp3Url: URL(string: "https://i.ganjoor.net/a/2130-ff.mp3")!,
                       syncUrl: URL(string: "https://api.ganjoor.net/api/audio/xml/2840"),
                       order: 1, type: 0, synced: true),
        ]
    )
}

/// Wraps a preview in the full environment the app provides at runtime.
@MainActor
struct PreviewContainer<Content: View>: View {
    @State private var model = AppModel.preview()
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .environment(model)
            .environment(model.settings)
            .environment(model.progress)
            .environment(model.audio)
            .environment(\.contentRepository, model.content)
            .environment(\.layoutDirection, .rightToLeft)
            .environment(\.locale, Locale(identifier: "fa_IR"))
            .environment(\.calendar, Calendar(identifier: .persian))
            .font(.app(.body))
            .modelContainer(model.container)
    }
}

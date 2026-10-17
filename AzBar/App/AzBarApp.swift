import SwiftUI

@main
struct AzBarApp: App {
    @State private var model = AppModel.live()

    init() {
        UIKitAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
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
}

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
                .environment(model.gamification)
                .environment(\.contentRepository, model.content)
                .persianRoot()
                .font(.app(.body))
                .preferredColorScheme(.light)
                .tint(Theme.Palette.teal)
                .modelContainer(model.container)
        }
    }
}

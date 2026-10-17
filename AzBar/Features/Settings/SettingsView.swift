// PLACEHOLDER (WP0): WP4 overwrites this file, keeping `struct SettingsView: View` with `init()`
import SwiftUI

struct SettingsView: View {
    var body: some View {
        ContentUnavailableView("تنظیمات", systemImage: "gearshape")
            .navigationTitle("تنظیمات")
    }
}

// PLACEHOLDER (WP0): WP4 overwrites this file, keeping `struct TodayView: View` with `init()`
import SwiftUI

struct TodayView: View {
    var body: some View {
        ContentUnavailableView("امروز", systemImage: "sun.max")
            .navigationTitle("امروز")
    }
}

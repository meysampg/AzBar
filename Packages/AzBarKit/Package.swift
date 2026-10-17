// swift-tools-version: 6.2
import PackageDescription
let package = Package(
  name: "AzBarKit",
  platforms: [.iOS(.v26), .macOS(.v15)],
  products: [.library(name: "AzBarKit", targets: ["AzBarKit"])],
  targets: [
    .target(name: "AzBarKit"),
    .testTarget(name: "AzBarKitTests", dependencies: ["AzBarKit"], resources: [.copy("Fixtures")])
  ]
)

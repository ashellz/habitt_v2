// swift-tools-version:5.9
// The widget snapshot model of the iOS home screen widgets, as a package so it
// can be unit tested on the Mac with `swift test` (see docs/home_widgets.md).
// The HabittWidgets extension compiles the same source file directly; it does
// not link this package.
import PackageDescription

let package = Package(
  name: "HabittWidgetsCore",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    .library(name: "HabittWidgetsCore", targets: ["HabittWidgetsCore"])
  ],
  targets: [
    .target(name: "HabittWidgetsCore"),
    .testTarget(name: "HabittWidgetsCoreTests", dependencies: ["HabittWidgetsCore"]),
  ]
)

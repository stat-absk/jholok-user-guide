// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DemoDump",
    platforms: [.macOS(.v26)],
    dependencies: [.package(path: "../../../JholokKit")],
    targets: [
        .executableTarget(name: "DemoDump", dependencies: [.product(name: "JholokKit", package: "JholokKit")]),
    ]
)

// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ReleaseKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "ReleaseKit",
            targets: ["ReleaseKit"]),
    ],
    targets: [
        .target(
            name: "ReleaseKit",
            resources: [.copy("PrivacyInfo.xcprivacy")]),
        .testTarget(
            name: "ReleaseKitTests",
            dependencies: ["ReleaseKit"]),
    ])

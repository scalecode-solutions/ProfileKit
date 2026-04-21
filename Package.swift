// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "ProfileKit",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(
            name: "ProfileKit",
            targets: ["ProfileKit"]
        ),
    ],
    targets: [
        .target(
            name: "ProfileKit"
        ),
        .testTarget(
            name: "ProfileKitTests",
            dependencies: ["ProfileKit"]
        ),
    ],
    swiftLanguageModes: [.v6]
)

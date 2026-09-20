// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IMacKey",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "i-mac-key", targets: ["IMacKey"])],
    targets: [
        .executableTarget(
            name: "IMacKey",
            path: "Sources/IMacKey",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)

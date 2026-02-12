// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SwiftADBTool",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SwiftADBTool", targets: ["SwiftADBTool"])
    ],
    targets: [
        .executableTarget(
            name: "SwiftADBTool",
            path: "Sources/SwiftADBTool",
            resources: [
                .process("Resources/AppIcon.icns"),
                .process("Resources/AppIcon-1024.png")
            ]
        )
    ]
)

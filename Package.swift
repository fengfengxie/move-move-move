// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MoveApp",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MoveApp",
            targets: ["MoveApp"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MoveApp",
            path: ".",
            exclude: [
                "README.md",
                "Info.plist",
                "build.sh",
                ".gitignore"
            ],
            sources: [
                "App",
                "Core",
                "UI"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)

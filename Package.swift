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
                "TESTING.md",
                "Info.plist",
                "build.sh",
                "generate_app_icon.sh",
                ".gitignore",
                "Tests"
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

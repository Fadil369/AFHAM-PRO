// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AFHAM",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AFHAM",
            targets: ["AFHAM"]
        )
    ],
    dependencies: [
        // Add any external dependencies here if needed
        // Example: .package(url: "https://github.com/example/package", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AFHAM",
            dependencies: [],
            path: ".",
            sources: [
                "afham_main.swift",
                "afham_chat.swift",
                "afham_content.swift",
                "afham_ui.swift",
                "afham_entry.swift",
                "LocalizationManager.swift",
                "AFHAMConstants.swift",
                "AFHAM/Core/UI/GlassMorphism.swift",
                "AFHAM/Core/UI/AccessibilityHelpers.swift",
                "AFHAM/Core/UI/FlowLayout.swift",
                "AFHAM/Features/UI/Components/MissionCardView.swift",
                "AFHAM/Features/UI/Components/DocumentCapsule.swift"
            ]
        ),
        .testTarget(
            name: "AFHAMTests",
            dependencies: ["AFHAM"],
            path: "Tests"
        )
    ]
)
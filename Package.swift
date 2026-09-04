// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Isle",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Isle", targets: ["Isle"])
    ],
    targets: [
        .executableTarget(
            name: "Isle",
            path: "Sources/Isle",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)

// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "SFSymbolsCompatKit",
    platforms: [
        .iOS("7.0")
    ],
    products: [
        .library(
            name: "SFSymbolsCompatKit",
            targets: ["SFSymbolsCompatKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SFSymbolsCompatKit",
            dependencies: []
        ),
        .testTarget(
            name: "SFSymbolsCompatKitTests",
            dependencies: ["SFSymbolsCompatKit"]
        ),
    ]
)

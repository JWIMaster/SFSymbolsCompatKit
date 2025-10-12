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
            dependencies: [],
            resources: [
                // Manually include every resource file
                .copy("Assets/lookup.dat"),
                .copy("Assets/SFSymbols-ultralight.ttf"),
                .copy("Assets/SFSymbols-thin.ttf"),
                .copy("Assets/SFSymbols-light.ttf"),
                .copy("Assets/SFSymbols-regular.ttf"),
                .copy("Assets/SFSymbols-medium.ttf"),
                .copy("Assets/SFSymbols-semibold.ttf"),
                .copy("Assets/SFSymbols-bold.ttf"),
                .copy("Assets/SFSymbols-heavy.ttf"),
                .copy("Assets/SFSymbols-black.ttf")
            ]
        ),
        .testTarget(
            name: "SFSymbolsCompatKitTests",
            dependencies: ["SFSymbolsCompatKit"]
        ),
    ]
)

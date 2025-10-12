// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SFSymbolsCompatKit",
    platforms: [
        .iOS("7.0")
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SFSymbolsCompatKit",
            targets: ["SFSymbolsCompatKit"]),
    ],
    dependencies: [

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SFSymbolsCompatKit",
            dependencies: [],
            resources: [
                .copy("Assets") // <-- include all your SVGs here
            ]
        ),
        
            .testTarget(
                name: "SFSymbolsCompatKitTests",
                dependencies: ["SFSymbolsCompatKit"]),
    ]
)

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BottomPanel",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BottomPanel",
            targets: ["BottomPanel"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nczoltan/DelegateProxy", branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BottomPanel",
            dependencies: [
                .product(name: "DelegateProxy", package: "DelegateProxy")
            ]
        ),
        .testTarget(
            name: "BottomPanelTests",
            dependencies: ["BottomPanel"]),
    ]
)

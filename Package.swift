// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "MetricConversion",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "MetricConversion", targets: ["MetricConversion"])
    ],
    targets: [
        .executableTarget(name: "MetricConversion", exclude: ["Info.plist"]),
        .testTarget(name: "MetricConversionTests", dependencies: ["MetricConversion"])
    ]
)
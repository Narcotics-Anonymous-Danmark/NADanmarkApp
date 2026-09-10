// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "adapter_legacy_store",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "adapter-legacy-store", targets: ["adapter_legacy_store"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "adapter_legacy_store",
            dependencies: [],
            resources: []
        )
    ]
)

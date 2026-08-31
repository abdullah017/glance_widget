// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "glance_widget_ios",
    platforms: [
        // `AppIntentConfiguration` -- the only widget configuration that carries
        // a per-instance parameter, and so the only way a placed widget can know
        // which `widgetId` it renders -- requires iOS 17.
        .iOS("17.0")
    ],
    products: [
        .library(name: "glance-widget-ios", targets: ["glance_widget_ios"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "glance_widget_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                // This plugin reads and writes App Group `UserDefaults`, which is a
                // required-reason API, so the privacy manifest is always bundled.
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)

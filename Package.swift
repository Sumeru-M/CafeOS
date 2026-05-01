// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CafeOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "CafeOS", targets: ["CafeOS"])
    ],
    dependencies: [
        // Firebase iOS SDK
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            from: "10.24.0"
        ),
        // SwiftSoup for HTML parsing (Job Scraper feature)
        .package(
            url: "https://github.com/scinfu/SwiftSoup.git",
            from: "2.7.0"
        )
    ],
    targets: [
        .target(
            name: "CafeOS",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreCombine-Community", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ],
            path: "Sources/CafeOS"
        )
    ]
)

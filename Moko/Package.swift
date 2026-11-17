// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Moko",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Moko",
            targets: ["Moko"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.4.3"),
    ],
    targets: [
        .target(
            name: "Moko",
            dependencies: [
                .product(name: "Lottie", package: "lottie-ios")
            ],
            path: "Moko"
        )
    ]
)
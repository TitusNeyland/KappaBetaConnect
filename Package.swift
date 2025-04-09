// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "KappaBetaConnect",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "KappaBetaConnect",
            targets: ["KappaBetaConnect"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
    ],
    targets: [
        .target(
            name: "KappaBetaConnect",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
            ]),
        .testTarget(
            name: "KappaBetaConnectTests",
            dependencies: ["KappaBetaConnect"]),
    ]
) 
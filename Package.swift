// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MomentumOS",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        // Data persistence
        .package(url: "https://github.com/apple/swift-foundation.git", from: "1.0.0"),
        
        // Networking
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        
        // JSON encoding/decoding
        .package(url: "https://github.com/apple/swift-async-algorithms.git", from: "1.0.0"),
        
        // Cryptography for encrypted sync
        .package(url: "https://github.com/apple/swift-crypto.git", from: "2.6.0"),
        
        // Analytics (optional)
        .package(url: "https://github.com/amplitude/Amplitude-Swift.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "MomentumOS",
            dependencies: [
                .product(name: "Foundation", package: "swift-foundation"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "AsyncAlgorithms", package: "swift-async-algorithms"),
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "Amplitude", package: "Amplitude-Swift"),
            ]
        ),
    ]
)

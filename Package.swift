// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tokengochi",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "TokengochiKit"),
        .executableTarget(name: "Tokengochi", dependencies: ["TokengochiKit"]),
        .executableTarget(name: "TokengochiWriter", dependencies: ["TokengochiKit"]),
        .executableTarget(name: "TokengochiPoller", dependencies: ["TokengochiKit"]),
        .executableTarget(name: "TokengochiCodexWriter", dependencies: ["TokengochiKit"]),
        .testTarget(name: "TokengochiKitTests", dependencies: ["TokengochiKit"])
    ]
)

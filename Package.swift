// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "SwiftSIP",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftSIP", targets: ["SwiftSIP"]),
    ],
    targets: [
        .binaryTarget(
            name: "libpjproject",
            url: "https://github.com/oliverepper/pjproject-apple-platforms/releases/download/0.8.1/libpjproject.xcframework-0.8.1.zip", checksum: "d47671ad29cab859b6d2db4614877c22c20257b7047985447a9794f1421e5be1"),
        .target(name: "Cpjproject", dependencies: ["libpjproject"]),
        .target(name: "Controller", dependencies: ["libpjproject"], cxxSettings: [
            .define("PJ_AUTOCONF")
        ], linkerSettings: [
            .linkedFramework("Network"),
            .linkedFramework("Security"),
            .linkedFramework("CoreAudio"),
            .linkedFramework("AVFoundation"),
            .linkedFramework("AudioToolbox")
        ]),
        .target(name: "SwiftSIP", dependencies: ["Controller"], cxxSettings: [
            .define("PJ_AUTOCONF")
        ]),
        .testTarget(name: "SwiftSIPTests", dependencies: ["SwiftSIP"], cxxSettings: [
            .define("PJ_AUTOCONF")
        ]),
    ],
    cxxLanguageStandard: .cxx20
)


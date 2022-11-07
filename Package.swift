// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "SwiftSIP",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "SwiftSIP", targets: ["SwiftSIP"]),
    ],
    targets: [
        .binaryTarget(name: "libpjproject", url: "https://github.com/oliverepper/pjproject-apple-platforms/releases/download/0.10.1/libpjproject.xcframework.zip", checksum: "eb3816a874f7fdcf47ce68b8efab924ee563d4534cbbb8ff4c88ea522b775f8c"),
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


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
        .binaryTarget(name: "libpjproject", url: "https://github.com/oliverepper/pjproject-apple-platforms/releases/download/0.10/libpjproject.xcframework-0.10.zip", checksum: "2e728e891c07d7bd347fa527b655120acb515a361b099e2f543f1ee98ecc448f"),
//        .binaryTarget(name: "libpjproject", path: "libpjproject.xcframework"),
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


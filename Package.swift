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
        .binaryTarget(name: "libpjproject", url: "https://github.com/oliverepper/pjproject-apple-platforms/releases/download/0.9/libpjproject.xcframework-0.9.zip", checksum: "f60e3ac30329b22172f7aea16007e81623dddf81941fda29139af1c1b2b15399"),
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


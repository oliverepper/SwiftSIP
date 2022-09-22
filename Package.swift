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
        .binaryTarget(name: "libpjproject", path: "libpjproject.xcframework"),
        .systemLibrary(name: "Cpjproject", pkgConfig: "pjproject-apple-platforms-SPM"),
        .target(name: "Controller", dependencies: ["libpjproject","Cpjproject"], cxxSettings: [
            .define("PJ_AUTOCONF")
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

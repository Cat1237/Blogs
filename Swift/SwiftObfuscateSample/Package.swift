// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import class Foundation.ProcessInfo

let macOSPlatform: SupportedPlatform
if let deploymentTarget = ProcessInfo.processInfo.environment["SWIFTTSC_MACOS_DEPLOYMENT_TARGET"] {
    macOSPlatform = .macOS(deploymentTarget)
} else {
    macOSPlatform = .macOS(.v10_13)
}
let package = Package(
    name: "Obfuscate",
    platforms: [
        macOSPlatform
    ],
    products: [
        .executable(name: "Obfuscate", targets: ["Obfuscate"])
    ],
    targets: [
        .target(name: "sourcekittd",
               dependencies: []),
        .target(
            name: "Obfuscate",
            dependencies: [
                "sourcekittd",
                .product(name: "TSCBasic", package: "swift-tools-support-core")]),
    ]
)

package.dependencies += [
         .package(url: "https://github.com/apple/swift-tools-support-core.git", .upToNextMinor(from: "0.2.7")),
     ]

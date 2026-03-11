// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftUI-Sturdy",
    platforms: [
        .iOS(.v16),
        .macOS(.v15),
    ],
    products: [
        .library(
            name: "SwiftUIMacroSturdy",
            targets: ["SwiftUIMacroSturdy"]
        )
    ],
    dependencies: [
        // Swift Syntax for macro implementation
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        .macro(
            name: "MacroSturdy",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/MacroSturdy"
        ),
        // Public macro client (what users import)
        .target(
            name: "SwiftUIMacroSturdy",
            dependencies: ["MacroSturdy"],
            path: "Sources/SwiftUIMacroSturdy"
        ),
    ],
)

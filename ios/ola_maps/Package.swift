// swift-tools-version: 5.9
import Foundation
import PackageDescription

private let olaMapFrameworks = [
  "OlaMapCore",
  "MapLibre",
  "MoEngageAnalytics",
  "MoEngageCards",
  "MoEngageCore",
  "MoEngageInApps",
  "MoEngageMessaging",
  "MoEngageObjCUtils",
  "MoEngageSDK",
  "MoEngageSecurity",
  "MoEngageTriggerEvaluator",
]

private func ensureOlaMapSDK() {
  let packageRoot = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
  let frameworksDir = packageRoot.appendingPathComponent("Frameworks")
  let marker = frameworksDir.appendingPathComponent("OlaMapCore.xcframework")
  if FileManager.default.fileExists(atPath: marker.path) {
    return
  }

  try? FileManager.default.createDirectory(at: frameworksDir, withIntermediateDirectories: true)

  let script = packageRoot
    .deletingLastPathComponent()
    .appendingPathComponent("download_olamap_sdk.sh")
  let process = Process()
  process.executableURL = URL(fileURLWithPath: "/bin/bash")
  process.arguments = [script.path, frameworksDir.path]
  do {
    try process.run()
    process.waitUntilExit()
  } catch {
    fputs("ola_maps: failed to download Ola Maps iOS SDK: \(error)\n", stderr)
  }

  if !FileManager.default.fileExists(atPath: marker.path) {
    fatalError(
      "Ola Maps iOS SDK frameworks are missing. Run ios/download_olamap_sdk.sh and try again."
    )
  }
}

ensureOlaMapSDK()

let package = Package(
  name: "ola_maps",
  platforms: [
    .iOS("15.0"),
  ],
  products: [
    .library(name: "ola-maps", targets: ["ola_maps"]),
  ],
  dependencies: [
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
  ],
  targets: [
    .target(
      name: "ola_maps",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        "OlaMapCore",
        "MapLibre",
        "MoEngageAnalytics",
        "MoEngageCards",
        "MoEngageCore",
        "MoEngageInApps",
        "MoEngageMessaging",
        "MoEngageObjCUtils",
        "MoEngageSDK",
        "MoEngageSecurity",
        "MoEngageTriggerEvaluator",
      ],
      resources: [
        .process("PrivacyInfo.xcprivacy"),
      ]
    ),
  ] + olaMapFrameworks.map { name in
    .binaryTarget(
      name: name,
      path: "Frameworks/\(name).xcframework"
    )
  }
)

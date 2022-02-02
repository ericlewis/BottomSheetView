// swift-tools-version: 5.5

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import AppleProductTypes
import PackageDescription

let package = Package(
  name: "Example",
  platforms: [
    .iOS("15.2")
  ],
  products: [
    .iOSApplication(
      name: "Example",
      targets: ["AppModule"],
      bundleIdentifier: "com.Example",
      teamIdentifier: "F9PGNEMEHU",
      displayVersion: "1.0",
      bundleVersion: "1",
      iconAssetName: "AppIcon",
      accentColorAssetName: "AccentColor",
      supportedDeviceFamilies: [
        .pad,
        .phone,
      ],
      supportedInterfaceOrientations: [
        .portrait,
        .landscapeRight,
        .landscapeLeft,
        .portraitUpsideDown(.when(deviceFamilies: [.pad])),
      ]
    )
  ],
  dependencies: [
    .package(path: "../../")
  ],
  targets: [
    .executableTarget(
      name: "AppModule",
      dependencies: [
        "PageSheet",
        .product(name: "PageSheetPlus", package: "PageSheet"),
      ],
      path: "."
    )
  ]
)

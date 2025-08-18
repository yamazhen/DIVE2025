import ProjectDescription

let project = Project(
    name: "DIVE_APPLE",
    targets: [
        .target(
            name: "DIVE_APPLE",
            destinations: .watchOS,
            product: .app,
            bundleId: "dev.tuist.DIVE-APPLE.watchkitapp",
            infoPlist: .extendingDefault(with: [
                "WKApplication": true,
                "WKCompanionAppBundleIdentifier": "dev.tuist.DIVE-APPLE"
            ]),
            sources: ["DIVE_APPLE/Sources/**"],
            resources: ["DIVE_APPLE/Resources/**"],
            dependencies: []
        ),
        .target(
            name: "DIVE_APPLETests",
            destinations: .watchOS,
            product: .unitTests,
            bundleId: "dev.tuist.DIVE-APPLETests",
            infoPlist: .default,
            sources: ["DIVE_APPLE/Tests/**"],
            resources: [],
            dependencies: [.target(name: "DIVE_APPLE")]
        ),
    ]
)

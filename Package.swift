// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-measure",
  products: [
    .library( // This library brings partial source-compatibility with swift-benchmark.
      name: "Benchmark",
      targets: ["Benchmark"]
    ),
    .library(
      name: "Measure",
      targets: ["Measure"]
    ),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "Benchmark",
      dependencies: ["Measure"]
    ),
    .testTarget(
      name: "BenchmarkTests",
      dependencies: ["Benchmark"]
    ),
    .target(
      name: "Measure",
      dependencies: [
      ]
    ),
    .testTarget(
      name: "MeasureTests",
      dependencies: ["Measure"]
    ),
  ]
)

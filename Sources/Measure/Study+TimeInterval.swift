import Foundation

public extension Study where Input == Void, Output == Measure<TimeInterval> {
  /// Adds a case where the execution time of the provided block is measured. See ``measureTime(_:tag:_:)`` for more information.
  @_disfavoredOverload
  mutating func benchmark(
    _ label: String,
    tag: AnyHashable? = nil,
    iterations: Range<Int> = 1 ..< 1_000_000,
    duration: Range<TimeInterval> = 0 ..< 5,
    block: @escaping (_ measure: (Signpost) -> Void) throws -> Void
  ) {
    cases.append(
      measureTime(label, tag: tag, block)
        .repeat(iterations: iterations, duration: duration)
        .map { $0.extractMeasure() }
        .unwrap(default: 0.0)
    )
  }

  /// Adds a baseline case where the execution time of the provided block is measured. See ``measureTime(_:tag:_:)`` for more information.
  @_disfavoredOverload
  mutating func benchmarkReference(
    _ label: String = "Reference",
    iterations: Range<Int> = 1 ..< 1_000_000,
    duration: Range<TimeInterval> = 0 ..< 5,
    block: @escaping (_ measure: (Signpost) -> Void) throws -> Void
  ) {
    benchmark(
      label,
      tag: baselineTag,
      iterations: iterations,
      duration: duration,
      block: block
    )
  }

  // MARK: Variants without Signposts
  
  /// Adds a case where the execution time of the provided block is measured. See ``measureTime(_:tag:_:)`` for more information.
  mutating func benchmark(
    _ label: String,
    tag: AnyHashable? = nil,
    iterations: Range<Int> = 1 ..< 1_000_000,
    duration: Range<TimeInterval> = 0 ..< 5,
    block: @escaping () throws -> Void
  ) {
    benchmark(
      label,
      tag: tag,
      iterations: iterations,
      duration: duration,
      block: { _ in try block() }
    )
  }

  /// Adds a baseline case where the execution time of the provided block is measured. See ``measureTime(_:tag:_:)`` for more information.
  mutating func benchmarkReference(
    _ label: String = "Reference",
    iterations: Range<Int> = 1 ..< 1_000_000,
    duration: Range<TimeInterval> = 0 ..< 5,
    block: @escaping () throws -> Void
  ) {
    benchmark(
      label,
      tag: baselineTag,
      iterations: iterations,
      duration: duration,
      block: block
    )
  }
}

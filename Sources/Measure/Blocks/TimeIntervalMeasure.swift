import Foundation

/// Returns a block that measures the execution time of a provided closure.
///
/// A `measure`  function is provided as argument and can be used to fence the parts that need to measured.
/// Call `measure(.start)` to mark the start of the region of interest, and `measure(.stop)` to mark its end.
/// These calls are optional and the block boundaries will be used if one or both are missing.
public func measureTime(
  _ label: String = "",
  tag: AnyHashable? = nil,
  _ block: @escaping (_ measure: (Signpost) -> Void) throws -> Void
) -> Block<Void, TimeInterval> {
  .init(label, tag: tag) { _ in
    warnIfDebug()
    var explicitStartTime: UInt64?
    var explicitEndTime: UInt64?

    let explicitLimits: (Signpost) -> Void = {
      switch $0 {
      case .start:
        guard explicitStartTime == nil else {
          fatalError("`measure(.start)` was called more than once.")
        }
        explicitStartTime = now()
      case .stop:
        guard explicitEndTime == nil else {
          fatalError("`measure(.stop)` was called more than once.")
        }
        explicitEndTime = now()
      default:
        fatalError("Only `.start` and `.stop` signposts are supported in this context")
      }
    }

    let implicitStartTime = now()
    try block(explicitLimits)
    let implicitEndTime = now()

    let startTime = explicitStartTime ?? implicitStartTime
    let endTime = explicitEndTime ?? implicitEndTime

    return seconds(startTime ..< endTime)
  }
}

public extension Block {
  /// Returns a block that measures the execution time of the source block.
  /// The source's `Ouput` is discarded. This variant measure the whole block and doesn't use `SignPost`s.
  func measureTime() -> Block<Input, TimeInterval> {
    .init(label, tag: tag) { input in
      warnIfDebug()
      let startTime = now()
      try self(input)
      let endTime = now()
      return seconds(startTime ..< endTime)
    }
  }
}

private var userWasWarnedOfDebugMode: Bool = false
private func warnIfDebug() {
  #if DEBUG
    guard !userWasWarnedOfDebugMode else { return }
    print("""

    *********************************************************************************
      WARNING: Executing time interval measures in a potentially unoptimized build.
    *********************************************************************************

    """)
    userWasWarnedOfDebugMode = true
  #endif
}

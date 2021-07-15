import Foundation

public func now() -> UInt64 {
  if #available(iOS 10.0, macOS 10.12, *) {
    return clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
  } else {
    if timebase_info.denom == 0 {
      mach_timebase_info(&timebase_info)
    }
    return mach_absolute_time() * UInt64(timebase_info.numer) / UInt64(timebase_info.denom)
  }
}
private var timebase_info = mach_timebase_info_data_t(numer: 0, denom: 0)

public func seconds(_ nanoseconds: Range<UInt64>) -> TimeInterval {
  TimeInterval(nanoseconds.upperBound - nanoseconds.lowerBound) * 1e-9
}

public enum TimeUnit: Int {
  case s = 1
  case ms = 1000
  case µs = 1_000_000
  case ns = 1_000_000_000

  public var suffix: String {
    switch self {
    case .s: return "s"
    case .ms: return "ms"
    case .µs: return "µs"
    case .ns: return "ns"
    }
  }

  public static func preferredUnit(_ duration: TimeInterval) -> TimeUnit {
    let duration = abs(duration)
    if duration > 1 {
      return .s
    } else if duration > 1e-3 {
      return .ms
    } else if duration > 1e-6 {
      return .µs
    } else {
      return .ns
    }
  }
}

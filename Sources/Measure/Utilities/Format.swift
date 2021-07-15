import Foundation

public enum Format {}

public extension Format {
  static func integer(_ value: Int) -> String {
    String(format: "%d", value)
  }

  static func percent(_ value: Double) -> String {
    String(format: "%+.2f %%", 100 * value)
  }

  static func errorPercent(_ value: Double) -> String {
    String(format: "±%.2f %%", 100 * value)
  }

  static func factor(_ value: Double) -> String {
    String(format: "x%.2f", value)
  }
}

public extension Format {
  static func seconds(
    _ seconds: TimeInterval,
    withSign signed: Bool = false,
    _ unit: TimeUnit
  ) -> String {
    let fractionalDigits = unit == .ns ? ".0f" : ".3f" // No fraction digits for ns
    let format = signed ? "%+\(fractionalDigits) %@" : "%\(fractionalDigits) %@"
    return String(format: format, seconds * Double(unit.rawValue), unit.suffix)
  }
}

public extension Format {
  static func ruler(
    label: String = "",
    labelOffset: Int = 0,
    repeating char: Character = "-",
    length: Int
  ) -> String {
    let prefix = String(repeating: char, count: labelOffset)
    let suffixLength = max(0, length - label.count - labelOffset)
    let suffix = String(repeating: char, count: suffixLength)
    return prefix + label + suffix
  }
}

public enum HorizontalAlignment {
  case left
  case right
  case center
}

public extension Format {
  static func align(string: String, length: Int?, alignment: HorizontalAlignment = .right) -> String {
    guard let length = length else { return string }
    guard string.count <= length else { return String(string.prefix(length)) }
    let lengthDifference = length - string.count
    let padding = String(repeating: " ", count: lengthDifference)
    switch alignment {
    case .left:
      return string + padding
    case .right:
      return padding + string
    case .center:
      let padding = String(repeating: " ", count: lengthDifference / 2)
      return padding + string + padding + (lengthDifference.isMultiple(of: 2) ? "" : " ")
    }
  }
}

import Foundation
#if canImport(Accelerate)
import Accelerate
#endif

public struct Measure<FloatType> where FloatType: BinaryFloatingPoint {
  public init(value: FloatType, std: FloatType, count: Int) {
    self.value = value
    self.std = std
    self.count = count
  }

  public init(_ value: FloatType) {
    self.value = value
    std = 0
    count = 1
  }

  public var value: FloatType
  /// The standard deviation of the measure
  public var std: FloatType
  /// The population's size from which this measure was extracted
  public var count: Int
  /// The standard error of the measure
  public var error: FloatType { std / sqrt(FloatType(count)) }
}

extension Measure: ExpressibleByFloatLiteral {
  public init(floatLiteral value: FloatLiteralType) {
    self = .init(FloatType(value))
  }
}

extension Array where Element: BinaryFloatingPoint {
  public var measure: Measure<Element>? { extractMeasure() }

  func extractMeasure() -> Measure<Element>? {
    guard !isEmpty else { return nil }
    guard count > 1 else { return .init(value: first!, std: 0, count: 1) }

    #if canImport(Accelerate)
    if Element.self == Double.self {
      var mean: Double = 0.0
      var stdDev: Double = 0.0
      var unused: [Double] = self as! [Double] // Mandatory for <iOS9, macOS10.11
      vDSP_normalizeD(self as! [Double], 1, &unused, 1, &mean, &stdDev, vDSP_Length(count))
      return .init(value: mean as! Element, std: stdDev as! Element, count: count)
    }
    if Element.self == Float.self {
      var mean: Float = 0.0
      var stdDev: Float = 0.0
      var unused: [Float] = self as! [Float] // Mandatory for <iOS9, macOS10.11
      vDSP_normalize(self as! [Float], 1, &unused, 1, &mean, &stdDev, vDSP_Length(count))
      return .init(value: mean as! Element, std: stdDev as! Element, count: count)
    }
    #endif

    let mean = reduce(0,+) / Element(count)
    // Helping the compiler…
    let meanSquare = reduce(0) { $0 + ($1 - mean) * ($1 - mean) }
    let variance = meanSquare / Element(count)
    let stdDev = sqrt(variance)

    return .init(value: mean, std: stdDev, count: count)
  }
}

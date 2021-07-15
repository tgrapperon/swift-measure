import Foundation

public struct Header: Hashable {
  public init(_ identifier: String, label: String? = nil) {
    self.identifier = identifier
    self.label = label ?? identifier
  }

  public let identifier: String
  public let label: String

  public static let label = Header("Label", label: "")
  public static let best = Header("Best", label: "")
  public static let mean = Header("Mean", label: "Value")
  public static let delta = Header("Delta", label: "Difference")
  public static let variation = Header("Variation")
  public static let performance = Header("Performance")
  public static let standardError = Header("StandardError", label: "Error")
  public static let iterations = Header("Iterations")
}

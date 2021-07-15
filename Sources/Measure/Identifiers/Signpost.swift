public struct Signpost: RawRepresentable, Hashable {
  public var rawValue: Int
  public init(rawValue: Int) {
    self.rawValue = rawValue
  }

  public static let start = Signpost(rawValue: 1 << 0)
  public static let stop = Signpost(rawValue: 1 << 1)
}

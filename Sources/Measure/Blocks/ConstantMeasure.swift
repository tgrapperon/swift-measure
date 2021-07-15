/// Returns a block which always returns the same `Output`. This can be used for testing or to define static baselines.
public func always<Input, Output>(
  _ label: String = "",
  tag: AnyHashable? = nil,
  _ output: @escaping @autoclosure () -> Output
) -> Block<Input, Output> {
  .init(label, tag: tag) { _ in output() }
}

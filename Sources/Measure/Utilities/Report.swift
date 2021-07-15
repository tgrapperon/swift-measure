
func report(_ string: String, level indentationLevel: Int = 0, withoutNewLine: Bool = false) {
  print(String(repeating: "  ", count: indentationLevel) + string, terminator: withoutNewLine ? "" : "\n")
}

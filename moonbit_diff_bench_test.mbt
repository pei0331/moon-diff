///|
test "bench diff with shared edges" (it : @bench.T) {
  let old_text = "a".repeat(256) + "old" + "z".repeat(256)
  let new_text = "a".repeat(256) + "new" + "z".repeat(256)
  it.bench(() => @moonbit_diff.diff(old_text, new_text) |> ignore)
}

///|
test "bench diff with short replacement" (it : @bench.T) {
  it.bench(() => @moonbit_diff.diff("abcd", "axyd") |> ignore)
}

///|
test "should replace the changed tail byte" {
  let edit_script = @moonbit_diff.diff("abc", "abd")
  assert_true(
    edit_script.length() == 4,
    msg="should produce four edit operations",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Equal("a"),
    msg="should keep the first byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Equal("b"),
    msg="should keep the second byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Delete("c"),
    msg="should remove the old tail byte",
  )
  assert_true(
    edit_script[3] is @moonbit_diff.Insert("d"),
    msg="should insert the new tail byte",
  )
}

///|
test "should insert appended bytes" {
  let edit_script = @moonbit_diff.diff("ab", "abc")
  assert_true(
    edit_script.length() == 3,
    msg="should produce three edit operations",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Equal("a"),
    msg="should keep the first byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Equal("b"),
    msg="should keep the second byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Insert("c"),
    msg="should insert the appended byte",
  )
}

///|
test "should delete trailing bytes" {
  let edit_script = @moonbit_diff.diff("abc", "ab")
  assert_true(
    edit_script.length() == 3,
    msg="should produce three edit operations",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Equal("a"),
    msg="should keep the first byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Equal("b"),
    msg="should keep the second byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Delete("c"),
    msg="should delete the trailing byte",
  )
}

///|
test "should insert every byte for empty old text" {
  let edit_script = @moonbit_diff.diff("", "abc")
  assert_true(
    edit_script.length() == 3,
    msg="should return one insert per new byte",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Insert("a"),
    msg="should insert the first byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Insert("b"),
    msg="should insert the second byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Insert("c"),
    msg="should insert the third byte",
  )
}

///|
test "should delete every byte for empty new text" {
  let edit_script = @moonbit_diff.diff("abc", "")
  assert_true(
    edit_script.length() == 3,
    msg="should return one delete per old byte",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Delete("a"),
    msg="should delete the first byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Delete("b"),
    msg="should delete the second byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Delete("c"),
    msg="should delete the third byte",
  )
}

///|
test "should replace a single byte" {
  let edit_script = @moonbit_diff.diff("a", "b")
  assert_true(
    edit_script.length() == 2,
    msg="should return delete and insert for one-byte replacement",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Delete("a"),
    msg="should delete the old byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Insert("b"),
    msg="should insert the new byte",
  )
}

///|
test "should insert bytes in the middle" {
  let edit_script = @moonbit_diff.diff("ac", "abc")
  assert_true(
    edit_script.length() == 3,
    msg="should keep both sides around the inserted byte",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Equal("a"),
    msg="should keep the prefix byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Insert("b"),
    msg="should insert the middle byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Equal("c"),
    msg="should keep the suffix byte",
  )
}

///|
test "should delete bytes in the middle" {
  let edit_script = @moonbit_diff.diff("abc", "ac")
  assert_true(
    edit_script.length() == 3,
    msg="should keep both sides around the deleted byte",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Equal("a"),
    msg="should keep the prefix byte",
  )
  assert_true(
    edit_script[1] is @moonbit_diff.Delete("b"),
    msg="should delete the middle byte",
  )
  assert_true(
    edit_script[2] is @moonbit_diff.Equal("c"),
    msg="should keep the suffix byte",
  )
}

///|
test "should return empty script for two empty strings" {
  let edit_script = @moonbit_diff.diff("", "")
  assert_true(
    edit_script.length() == 0,
    msg="should return no edits when both inputs are empty",
  )
}

///|
test "should keep an identical single byte" {
  let edit_script = @moonbit_diff.diff("x", "x")
  assert_true(
    edit_script.length() == 1,
    msg="should keep the matching single byte",
  )
  assert_true(
    edit_script[0] is @moonbit_diff.Equal("x"),
    msg="should emit one equal operation",
  )
}

///|
fn assert_script_len(
  edit_script : Array[@moonbit_diff.EditOp],
  expected_len : Int,
  message : String,
) -> Unit raise {
  assert_true(edit_script.length() == expected_len, msg=message)
}

///|
fn assert_diff_op(
  edit_script : Array[@moonbit_diff.EditOp],
  offset : Int,
  diff_op : @moonbit_diff.EditOp,
  message : String,
) -> Unit raise {
  assert_true(edit_script[offset] == diff_op, msg=message)
}

///|
test "dmp source keeps empty inputs empty" {
  let edit_script = @moonbit_diff.diff("", "")
  assert_script_len(edit_script, 0, "should keep two empty inputs unchanged")
}

///|
test "dmp source inserts one byte into empty input" {
  let edit_script = @moonbit_diff.diff("", "a")
  assert_script_len(edit_script, 1, "should emit one insert")
  assert_diff_op(edit_script, 0, @moonbit_diff.Insert("a"), "should insert a")
}

///|
test "dmp source deletes one byte into empty output" {
  let edit_script = @moonbit_diff.diff("a", "")
  assert_script_len(edit_script, 1, "should emit one delete")
  assert_diff_op(edit_script, 0, @moonbit_diff.Delete("a"), "should delete a")
}

///|
test "dmp source keeps equal one byte input" {
  let edit_script = @moonbit_diff.diff("a", "a")
  assert_script_len(edit_script, 1, "should emit one equal op")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
}

///|
test "dmp source replaces one byte input" {
  let edit_script = @moonbit_diff.diff("a", "b")
  assert_script_len(edit_script, 2, "should emit delete and insert")
  assert_diff_op(edit_script, 0, @moonbit_diff.Delete("a"), "should delete a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Insert("b"), "should insert b")
}

///|
test "dmp source keeps equal two byte input" {
  let edit_script = @moonbit_diff.diff("ab", "ab")
  assert_script_len(edit_script, 2, "should keep both bytes")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("b"), "should keep b")
}

///|
test "dmp source inserts prefix byte" {
  let edit_script = @moonbit_diff.diff("bc", "abc")
  assert_script_len(edit_script, 3, "should insert prefix and keep suffix")
  assert_diff_op(edit_script, 0, @moonbit_diff.Insert("a"), "should insert a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("b"), "should keep b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("c"), "should keep c")
}

///|
test "dmp source inserts suffix byte" {
  let edit_script = @moonbit_diff.diff("ab", "abc")
  assert_script_len(edit_script, 3, "should keep prefix and insert suffix")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("b"), "should keep b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Insert("c"), "should insert c")
}

///|
test "dmp source deletes prefix byte" {
  let edit_script = @moonbit_diff.diff("abc", "bc")
  assert_script_len(edit_script, 3, "should delete prefix and keep suffix")
  assert_diff_op(edit_script, 0, @moonbit_diff.Delete("a"), "should delete a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("b"), "should keep b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("c"), "should keep c")
}

///|
test "dmp source deletes suffix byte" {
  let edit_script = @moonbit_diff.diff("abc", "ab")
  assert_script_len(edit_script, 3, "should keep prefix and delete suffix")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("b"), "should keep b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Delete("c"), "should delete c")
}

///|
test "dmp source inserts middle byte" {
  let edit_script = @moonbit_diff.diff("ac", "abc")
  assert_script_len(edit_script, 3, "should keep around middle insert")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Insert("b"), "should insert b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("c"), "should keep c")
}

///|
test "dmp source deletes middle byte" {
  let edit_script = @moonbit_diff.diff("abc", "ac")
  assert_script_len(edit_script, 3, "should keep around middle delete")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Delete("b"), "should delete b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("c"), "should keep c")
}

///|
test "dmp source replaces middle byte" {
  let edit_script = @moonbit_diff.diff("abc", "axc")
  assert_script_len(edit_script, 4, "should keep sides and replace middle")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Delete("b"), "should delete b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Insert("x"), "should insert x")
  assert_diff_op(edit_script, 3, @moonbit_diff.Equal("c"), "should keep c")
}

///|
test "dmp source keeps common prefix after suffix change" {
  let edit_script = @moonbit_diff.diff("kit", "kin")
  assert_script_len(edit_script, 4, "should keep prefix and replace suffix")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("k"), "should keep k")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("i"), "should keep i")
  assert_diff_op(edit_script, 2, @moonbit_diff.Delete("t"), "should delete t")
  assert_diff_op(edit_script, 3, @moonbit_diff.Insert("n"), "should insert n")
}

///|
test "dmp source handles separate inserts" {
  let edit_script = @moonbit_diff.diff("ace", "abcde")
  assert_script_len(
    edit_script, 5, "should place inserted bytes between matches",
  )
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Insert("b"), "should insert b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("c"), "should keep c")
  assert_diff_op(edit_script, 3, @moonbit_diff.Insert("d"), "should insert d")
  assert_diff_op(edit_script, 4, @moonbit_diff.Equal("e"), "should keep e")
}

///|
test "dmp source handles separate deletes" {
  let edit_script = @moonbit_diff.diff("abcde", "ace")
  assert_script_len(
    edit_script, 5, "should place deleted bytes between matches",
  )
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Delete("b"), "should delete b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("c"), "should keep c")
  assert_diff_op(edit_script, 3, @moonbit_diff.Delete("d"), "should delete d")
  assert_diff_op(edit_script, 4, @moonbit_diff.Equal("e"), "should keep e")
}

///|
test "dmp source handles full replacement" {
  let edit_script = @moonbit_diff.diff("abc", "xyz")
  assert_script_len(edit_script, 6, "should delete old bytes before inserts")
  assert_diff_op(edit_script, 0, @moonbit_diff.Delete("a"), "should delete a")
  assert_diff_op(edit_script, 1, @moonbit_diff.Delete("b"), "should delete b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Delete("c"), "should delete c")
  assert_diff_op(edit_script, 3, @moonbit_diff.Insert("x"), "should insert x")
  assert_diff_op(edit_script, 4, @moonbit_diff.Insert("y"), "should insert y")
  assert_diff_op(edit_script, 5, @moonbit_diff.Insert("z"), "should insert z")
}

///|
test "dmp source keeps repeated middle match" {
  let edit_script = @moonbit_diff.diff("banana", "bandana")
  assert_script_len(edit_script, 7, "should keep the repeated middle run")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("b"), "should keep b")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("n"), "should keep n")
  assert_diff_op(edit_script, 3, @moonbit_diff.Insert("d"), "should insert d")
  assert_diff_op(edit_script, 4, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(edit_script, 5, @moonbit_diff.Equal("n"), "should keep n")
  assert_diff_op(edit_script, 6, @moonbit_diff.Equal("a"), "should keep a")
}

///|
test "dmp source handles line break insert" {
  let edit_script = @moonbit_diff.diff("ab", "a\nb")
  assert_script_len(edit_script, 3, "should insert one line break")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(
    edit_script,
    1,
    @moonbit_diff.Insert("\n"),
    "should insert newline",
  )
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("b"), "should keep b")
}

///|
test "dmp source handles line break delete" {
  let edit_script = @moonbit_diff.diff("a\nb", "ab")
  assert_script_len(edit_script, 3, "should delete one line break")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep a")
  assert_diff_op(
    edit_script,
    1,
    @moonbit_diff.Delete("\n"),
    "should delete newline",
  )
  assert_diff_op(edit_script, 2, @moonbit_diff.Equal("b"), "should keep b")
}

///|
test "should keep delete operations before inserts for multiline replacement" {
  let edit_script = @moonbit_diff.diff("a\nold\nb", "a\nnew\nb")
  assert_script_len(edit_script, 10, "should keep line boundaries stable")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep prefix")
  assert_diff_op(edit_script, 1, @moonbit_diff.Equal("\n"), "should keep break")
  assert_diff_op(edit_script, 2, @moonbit_diff.Delete("o"), "should delete o")
  assert_diff_op(edit_script, 3, @moonbit_diff.Delete("l"), "should delete l")
  assert_diff_op(edit_script, 4, @moonbit_diff.Delete("d"), "should delete d")
  assert_diff_op(edit_script, 5, @moonbit_diff.Insert("n"), "should insert n")
  assert_diff_op(edit_script, 6, @moonbit_diff.Insert("e"), "should insert e")
  assert_diff_op(edit_script, 7, @moonbit_diff.Insert("w"), "should insert w")
  assert_diff_op(edit_script, 8, @moonbit_diff.Equal("\n"), "should keep break")
  assert_diff_op(edit_script, 9, @moonbit_diff.Equal("b"), "should keep suffix")
}

///|
test "should strip common prefix and suffix around middle replacement" {
  let edit_script = @moonbit_diff.diff("prefix-old-suffix", "prefix-new-suffix")
  assert_script_len(edit_script, 20, "should keep shared edges unchanged")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("p"), "should keep prefix")
  assert_diff_op(
    edit_script,
    6,
    @moonbit_diff.Equal("-"),
    "should keep divider",
  )
  assert_diff_op(edit_script, 7, @moonbit_diff.Delete("o"), "should delete o")
  assert_diff_op(edit_script, 8, @moonbit_diff.Delete("l"), "should delete l")
  assert_diff_op(edit_script, 9, @moonbit_diff.Delete("d"), "should delete d")
  assert_diff_op(edit_script, 10, @moonbit_diff.Insert("n"), "should insert n")
  assert_diff_op(edit_script, 11, @moonbit_diff.Insert("e"), "should insert e")
  assert_diff_op(edit_script, 12, @moonbit_diff.Insert("w"), "should insert w")
  assert_diff_op(
    edit_script,
    13,
    @moonbit_diff.Equal("-"),
    "should keep divider",
  )
  assert_diff_op(
    edit_script,
    19,
    @moonbit_diff.Equal("x"),
    "should keep suffix",
  )
}

///|
test "should use short input path without changing edit order" {
  let edit_script = @moonbit_diff.diff("abcd", "axyd")
  assert_script_len(edit_script, 6, "should keep edges and replace middle run")
  assert_diff_op(edit_script, 0, @moonbit_diff.Equal("a"), "should keep prefix")
  assert_diff_op(edit_script, 1, @moonbit_diff.Delete("b"), "should delete b")
  assert_diff_op(edit_script, 2, @moonbit_diff.Delete("c"), "should delete c")
  assert_diff_op(edit_script, 3, @moonbit_diff.Insert("x"), "should insert x")
  assert_diff_op(edit_script, 4, @moonbit_diff.Insert("y"), "should insert y")
  assert_diff_op(edit_script, 5, @moonbit_diff.Equal("d"), "should keep suffix")
}

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

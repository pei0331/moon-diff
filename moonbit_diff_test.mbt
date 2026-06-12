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

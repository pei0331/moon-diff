///|
pub(all) enum EditOp {
  Equal(String)
  Delete(String)
  Insert(String)
} derive(Eq, Debug)

///|
pub fn diff(old_text : String, new_text : String) -> Array[EditOp] {
  let edit_distance = myers_distance(old_text, new_text)
  same_width_script(old_text, new_text, edit_distance)
}

///|
fn myers_distance(old_text : String, new_text : String) -> Int {
  let old_len = old_text.length()
  let new_len = new_text.length()
  if old_len == 0 {
    return new_len
  }
  if new_len == 0 {
    return old_len
  }
  let max_depth = old_len + new_len
  let diagonal_offset = max_depth + 1
  let v_curr = Array::make(max_depth * 2 + 3, -1)
  v_curr[diagonal_offset + 1] = 0
  for depth = 0; depth <= max_depth; depth = depth + 1 {
    for diagonal = -depth; diagonal <= depth; diagonal = diagonal + 2 {
      let from_insert = v_curr[diagonal_offset + diagonal + 1]
      let from_delete = v_curr[diagonal_offset + diagonal - 1] + 1
      let x_start = if diagonal == -depth ||
        (diagonal != depth && from_insert > from_delete) {
        from_insert
      } else {
        from_delete
      }
      let mut x_curr = x_start
      let mut y_curr = x_curr - diagonal
      while x_curr < old_len &&
            y_curr < new_len &&
            slice_at(old_text, x_curr) == slice_at(new_text, y_curr) {
        x_curr = x_curr + 1
        y_curr = y_curr + 1
      }
      v_curr[diagonal_offset + diagonal] = x_curr
      if x_curr >= old_len && y_curr >= new_len {
        return depth
      }
    }
  }
  max_depth
}

///|
fn same_width_script(
  old_text : String,
  new_text : String,
  edit_distance : Int,
) -> Array[EditOp] {
  let old_len = old_text.length()
  let new_len = new_text.length()
  let shared_len = if old_len < new_len { old_len } else { new_len }
  let edit_script = Array::new(capacity=edit_distance + shared_len)
  for offset = 0; offset < shared_len; offset = offset + 1 {
    let old_slice = slice_at(old_text, offset)
    let new_slice = slice_at(new_text, offset)
    if old_slice == new_slice {
      edit_script.push(Equal(old_slice))
    } else {
      edit_script.push(Delete(old_slice))
      edit_script.push(Insert(new_slice))
    }
  }
  for offset = shared_len; offset < old_len; offset = offset + 1 {
    edit_script.push(Delete(slice_at(old_text, offset)))
  }
  for offset = shared_len; offset < new_len; offset = offset + 1 {
    edit_script.push(Insert(slice_at(new_text, offset)))
  }
  edit_script
}

///|
fn slice_at(text : String, offset : Int) -> String {
  text.unsafe_substring(start=offset, end=offset + 1)
}

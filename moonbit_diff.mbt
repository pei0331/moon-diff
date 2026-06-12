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
  let max_depth = old_len + new_len
  let v_offset = max_depth
  let v_frontier = Array::make(max_depth * 2 + 1, -1)
  v_frontier[v_offset + 1] = 0
  for depth = 0; depth <= max_depth; depth = depth + 1 {
    for diagonal = -depth; diagonal <= depth; diagonal = diagonal + 2 {
      let from_insert = v_frontier[v_offset + diagonal + 1]
      let from_delete = v_frontier[v_offset + diagonal - 1] + 1
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
      v_frontier[v_offset + diagonal] = x_curr
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
  let edit_script = Array::new(capacity=edit_distance + old_text.length())
  for offset = 0; offset < old_text.length(); offset = offset + 1 {
    let old_slice = slice_at(old_text, offset)
    let new_slice = slice_at(new_text, offset)
    if old_slice == new_slice {
      edit_script.push(Equal(old_slice))
    } else {
      edit_script.push(Delete(old_slice))
      edit_script.push(Insert(new_slice))
    }
  }
  edit_script
}

///|
fn slice_at(text : String, offset : Int) -> String {
  text.unsafe_substring(start=offset, end=offset + 1)
}

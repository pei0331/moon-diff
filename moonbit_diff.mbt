///|
pub(all) enum EditOp {
  Equal(String)
  Delete(String)
  Insert(String)
} derive(Eq, Debug)

///|
pub fn diff(old_text : String, new_text : String) -> Array[EditOp] {
  let edit_distance = myers_distance(old_text, new_text)
  traceback_script(old_text, new_text, edit_distance)
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
fn traceback_script(
  old_text : String,
  new_text : String,
  edit_distance : Int,
) -> Array[EditOp] {
  let old_len = old_text.length()
  let new_len = new_text.length()
  if old_len == 0 {
    return insert_only_script(new_text)
  }
  if new_len == 0 {
    return delete_only_script(old_text)
  }
  if old_len == 1 && new_len == 1 {
    return single_pair_script(old_text, new_text)
  }
  let matrix_width = new_len + 1
  let lcs_score = Array::make((old_len + 1) * matrix_width, 0)
  for old_back = 0; old_back < old_len; old_back = old_back + 1 {
    let old_pos = old_len - old_back - 1
    for new_back = 0; new_back < new_len; new_back = new_back + 1 {
      let new_pos = new_len - new_back - 1
      let score_pos = score_index(old_pos, new_pos, matrix_width)
      if slice_at(old_text, old_pos) == slice_at(new_text, new_pos) {
        lcs_score[score_pos] = lcs_score[score_index(
            old_pos + 1,
            new_pos + 1,
            matrix_width,
          )] +
          1
      } else {
        let delete_score = lcs_score[score_index(
            old_pos + 1,
            new_pos,
            matrix_width,
          )]
        let insert_score = lcs_score[score_index(
            old_pos,
            new_pos + 1,
            matrix_width,
          )]
        lcs_score[score_pos] = if delete_score >= insert_score {
          delete_score
        } else {
          insert_score
        }
      }
    }
  }
  let edit_script = Array::new(capacity=edit_distance + lcs_score[0])
  let mut old_pos = 0
  let mut new_pos = 0
  while old_pos < old_len && new_pos < new_len {
    let old_slice = slice_at(old_text, old_pos)
    let new_slice = slice_at(new_text, new_pos)
    if old_slice == new_slice {
      edit_script.push(Equal(old_slice))
      old_pos = old_pos + 1
      new_pos = new_pos + 1
    } else {
      let delete_score = lcs_score[score_index(
          old_pos + 1,
          new_pos,
          matrix_width,
        )]
      let insert_score = lcs_score[score_index(
          old_pos,
          new_pos + 1,
          matrix_width,
        )]
      if delete_score >= insert_score {
        edit_script.push(Delete(old_slice))
        old_pos = old_pos + 1
      } else {
        edit_script.push(Insert(new_slice))
        new_pos = new_pos + 1
      }
    }
  }
  while old_pos < old_len {
    edit_script.push(Delete(slice_at(old_text, old_pos)))
    old_pos = old_pos + 1
  }
  while new_pos < new_len {
    edit_script.push(Insert(slice_at(new_text, new_pos)))
    new_pos = new_pos + 1
  }
  edit_script
}

///|
fn insert_only_script(new_text : String) -> Array[EditOp] {
  let new_len = new_text.length()
  let edit_script = Array::new(capacity=new_len)
  for new_pos = 0; new_pos < new_len; new_pos = new_pos + 1 {
    edit_script.push(Insert(slice_at(new_text, new_pos)))
  }
  edit_script
}

///|
fn delete_only_script(old_text : String) -> Array[EditOp] {
  let old_len = old_text.length()
  let edit_script = Array::new(capacity=old_len)
  for old_pos = 0; old_pos < old_len; old_pos = old_pos + 1 {
    edit_script.push(Delete(slice_at(old_text, old_pos)))
  }
  edit_script
}

///|
fn single_pair_script(old_text : String, new_text : String) -> Array[EditOp] {
  let old_slice = slice_at(old_text, 0)
  let new_slice = slice_at(new_text, 0)
  let edit_script = Array::new(capacity=2)
  if old_slice == new_slice {
    edit_script.push(Equal(old_slice))
  } else {
    edit_script.push(Delete(old_slice))
    edit_script.push(Insert(new_slice))
  }
  edit_script
}

///|
fn score_index(old_pos : Int, new_pos : Int, matrix_width : Int) -> Int {
  old_pos * matrix_width + new_pos
}

///|
fn slice_at(text : String, offset : Int) -> String {
  text.unsafe_substring(start=offset, end=offset + 1)
}

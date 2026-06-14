///|
pub(all) enum EditOp {
  Equal(String)
  Delete(String)
  Insert(String)
} derive(Eq, Debug)

///|
pub fn diff(old_text : String, new_text : String) -> Array[EditOp] {
  let old_len = old_text.length()
  let new_len = new_text.length()
  let prefix_len = common_prefix_len(old_text, new_text, old_len, new_len)
  let suffix_len = common_suffix_len(
    old_text, new_text, old_len, new_len, prefix_len,
  )
  let old_middle = old_text.unsafe_substring(
    start=prefix_len,
    end=old_len - suffix_len,
  )
  let new_middle = new_text.unsafe_substring(
    start=prefix_len,
    end=new_len - suffix_len,
  )
  let middle_script = diff_middle(old_middle, new_middle)
  let edit_script = Array::new(
    capacity=prefix_len + middle_script.length() + suffix_len,
  )
  push_equal_range(edit_script, old_text, 0, prefix_len)
  push_script(edit_script, middle_script)
  push_equal_range(edit_script, old_text, old_len - suffix_len, old_len)
  edit_script
}

///|
pub fn unified_diff(old_text : String, new_text : String) -> String {
  let old_source = normalize_line_endings(old_text)
  let new_source = normalize_line_endings(new_text)
  if old_source == new_source {
    return ""
  }
  let old_lines = split_lines(old_source)
  let new_lines = split_lines(new_source)
  let line_script = line_diff(old_lines, new_lines)
  render_unified_diff(line_script, old_lines.length(), new_lines.length())
}

///|
fn diff_middle(old_text : String, new_text : String) -> Array[EditOp] {
  let total_len = old_text.length() + new_text.length()
  if total_len < 32 {
    return traceback_script(old_text, new_text, total_len)
  }
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
  if old_len == 0 && new_len == 0 {
    return Array::new(capacity=0)
  }
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
      if should_take_delete(delete_score, insert_score) {
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
fn split_lines(text : String) -> Array[String] {
  if text.length() == 0 {
    return Array::new(capacity=0)
  }
  text.split("\n").map(line => line.to_owned()).to_array()
}

///|
fn normalize_line_endings(text : String) -> String {
  let output = StringBuilder()
  let mut offset = 0
  while offset < text.length() {
    let current = slice_at(text, offset)
    if current == "\r" {
      output.write_string("\n")
      if offset + 1 < text.length() && slice_at(text, offset + 1) == "\n" {
        offset = offset + 2
      } else {
        offset = offset + 1
      }
    } else {
      output.write_string(current)
      offset = offset + 1
    }
  }
  output.to_string()
}

///|
fn line_diff(
  old_lines : Array[String],
  new_lines : Array[String],
) -> Array[EditOp] {
  let old_len = old_lines.length()
  let new_len = new_lines.length()
  if old_len == 0 {
    return insert_lines(new_lines)
  }
  if new_len == 0 {
    return delete_lines(old_lines)
  }
  let matrix_width = new_len + 1
  let lcs_score = Array::make((old_len + 1) * matrix_width, 0)
  for old_back = 0; old_back < old_len; old_back = old_back + 1 {
    let old_pos = old_len - old_back - 1
    for new_back = 0; new_back < new_len; new_back = new_back + 1 {
      let new_pos = new_len - new_back - 1
      let score_pos = score_index(old_pos, new_pos, matrix_width)
      if old_lines[old_pos] == new_lines[new_pos] {
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
  let line_script = Array::new(capacity=old_len + new_len)
  let mut old_pos = 0
  let mut new_pos = 0
  while old_pos < old_len && new_pos < new_len {
    let old_line = old_lines[old_pos]
    let new_line = new_lines[new_pos]
    if old_line == new_line {
      line_script.push(Equal(old_line))
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
      if should_take_delete(delete_score, insert_score) {
        line_script.push(Delete(old_line))
        old_pos = old_pos + 1
      } else {
        line_script.push(Insert(new_line))
        new_pos = new_pos + 1
      }
    }
  }
  while old_pos < old_len {
    line_script.push(Delete(old_lines[old_pos]))
    old_pos = old_pos + 1
  }
  while new_pos < new_len {
    line_script.push(Insert(new_lines[new_pos]))
    new_pos = new_pos + 1
  }
  line_script
}

///|
fn insert_lines(new_lines : Array[String]) -> Array[EditOp] {
  let line_script = Array::new(capacity=new_lines.length())
  for new_pos = 0; new_pos < new_lines.length(); new_pos = new_pos + 1 {
    line_script.push(Insert(new_lines[new_pos]))
  }
  line_script
}

///|
fn delete_lines(old_lines : Array[String]) -> Array[EditOp] {
  let line_script = Array::new(capacity=old_lines.length())
  for old_pos = 0; old_pos < old_lines.length(); old_pos = old_pos + 1 {
    line_script.push(Delete(old_lines[old_pos]))
  }
  line_script
}

///|
fn render_unified_diff(
  line_script : Array[EditOp],
  old_len : Int,
  new_len : Int,
) -> String {
  let output = StringBuilder()
  output.write_string("--- old\n")
  output.write_string("+++ new\n")
  output.write_string("@@ -1,\{old_len} +1,\{new_len} @@\n")
  for offset = 0; offset < line_script.length(); offset = offset + 1 {
    match line_script[offset] {
      Equal(line) => output.write_string(" \{line}\n")
      Delete(line) => output.write_string("-\{line}\n")
      Insert(line) => output.write_string("+\{line}\n")
    }
  }
  output.to_string()
}

///|
fn should_take_delete(delete_score : Int, insert_score : Int) -> Bool {
  delete_score >= insert_score
}

///|
fn common_prefix_len(
  old_text : String,
  new_text : String,
  old_len : Int,
  new_len : Int,
) -> Int {
  let max_len = if old_len < new_len { old_len } else { new_len }
  let mut offset = 0
  while offset < max_len &&
        slice_at(old_text, offset) == slice_at(new_text, offset) {
    offset = offset + 1
  }
  offset
}

///|
fn common_suffix_len(
  old_text : String,
  new_text : String,
  old_len : Int,
  new_len : Int,
  prefix_len : Int,
) -> Int {
  let max_len = if old_len < new_len { old_len } else { new_len }
  let mut offset = 0
  while offset < max_len - prefix_len &&
        slice_at(old_text, old_len - offset - 1) ==
        slice_at(new_text, new_len - offset - 1) {
    offset = offset + 1
  }
  offset
}

///|
fn push_equal_range(
  edit_script : Array[EditOp],
  text : String,
  start : Int,
  end : Int,
) -> Unit {
  for offset = start; offset < end; offset = offset + 1 {
    edit_script.push(Equal(slice_at(text, offset)))
  }
}

///|
fn push_script(
  edit_script : Array[EditOp],
  other_script : Array[EditOp],
) -> Unit {
  for offset = 0; offset < other_script.length(); offset = offset + 1 {
    edit_script.push(other_script[offset])
  }
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

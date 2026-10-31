///|
/// Small, dependency-free text helpers. The project deliberately avoids a
/// regex/Unicode dependency: the input domain is Han characters plus
/// punctuation, and keeping the parsing rules explicit makes the checker
/// auditable.
fn split_on(s : String, sep : Char) -> Array[String] {
  let out : Array[String] = []
  let sb = StringBuilder()
  for c in s {
    if c == sep {
      out.push(sb.to_string())
      let _ = sb.reset()
    } else {
      sb.write_char(c)
    }
  }
  out.push(sb.to_string())
  out
}

///|
fn has_prefix(s : String, prefix : String) -> Bool {
  let a = s.to_array()
  let b = prefix.to_array()
  if a.length() < b.length() {
    return false
  }
  let mut i = 0
  while i < b.length() {
    if a[i] != b[i] {
      return false
    }
    i = i + 1
  }
  true
}

///|
pub fn parse_int_opt(s : String) -> Int32? {
  if s.length() == 0 {
    return None
  }
  let mut value = 0
  for c in s {
    let d = c.to_int() - '0'.to_int()
    if d < 0 || d > 9 {
      return None
    }
    value = value * 10 + d
  }
  Some(value)
}

///|
/// True for the CJK Unified Ideographs blocks we accept as poem characters.
/// Punctuation, Latin letters and digits act as line separators instead.
pub fn is_han(c : Char) -> Bool {
  let n = c.to_int()
  (n >= 0x4E00 && n <= 0x9FFF) ||
  (n >= 0x3400 && n <= 0x4DBF) ||
  (n >= 0xF900 && n <= 0xFAFF)
}

///|
/// Split a pasted poem into lines of Han characters.
///
/// Every non-Han character (，。、；：！？, newline, spaces, annotations) ends
/// the current line. This mirrors how people actually paste poems and makes
/// the checker independent of a particular punctuation style.
pub fn poem_lines(text : String) -> Array[String] {
  let out : Array[String] = []
  let sb = StringBuilder()
  let mut pending = 0
  for c in text {
    if is_han(c) {
      sb.write_char(c)
      pending = pending + 1
    } else if pending > 0 {
      out.push(sb.to_string())
      let _ = sb.reset()
      pending = 0
    }
  }
  let tail = sb.to_string()
  if tail.length() > 0 {
    out.push(tail)
  }
  out
}

///|
pub fn chars_of(s : String) -> Array[Char] {
  s.to_array()
}

///|
pub fn string_of_chars(cs : Array[Char]) -> String {
  let sb = StringBuilder()
  for c in cs {
    sb.write_char(c)
  }
  sb.to_string()
}

///|
pub fn repeat_char(c : Char, n : Int32) -> String {
  let sb = StringBuilder()
  let mut i = 0
  while i < n {
    sb.write_char(c)
    i = i + 1
  }
  sb.to_string()
}

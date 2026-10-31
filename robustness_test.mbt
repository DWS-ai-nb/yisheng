///|
/// Deterministic smoke test: arbitrary inputs must produce a report, never a
/// panic. This is deliberately not a correctness oracle.
test "arbitrary input never crashes the checkers" {
  let lex = @yisheng.Lexicon::builtin()
  let alphabet = "天地玄黄宇宙洪荒日月盈昃辰宿列张龘〇，。！？abc123 "
  let chars = alphabet.to_array()
  let mut seed = 7
  for _ in 0..<300 {
    seed = (seed * 37 + 11) % 100003
    let n = seed % 40
    let sb = StringBuilder()
    for _ in 0..<n {
      seed = (seed * 37 + 11) % 100003
      sb.write_char(chars[seed % chars.length()])
    }
    let text = sb.to_string()
    let shi = @yisheng.check_shi(lex, text, None)
    let ci = @yisheng.check_ci(lex, text, None)
    let _ = @yisheng.identify_ci(lex, text)
    // A report must always identify what it attempted to check.
    assert_true(shi.form.length() > 0)
    assert_true(ci.form.length() > 0)
  }
}

///|
test "empty and punctuation-only input are reported, not dropped" {
  let lex = @yisheng.Lexicon::builtin()
  let empty = @yisheng.check_shi(lex, "", None)
  assert_false(empty.ok)
  assert_eq(empty.issues[0].code, "SHI_SHAPE")
  let punct = @yisheng.check_ci(lex, "，。！？", None)
  assert_false(punct.ok)
}

///|
test "lexicon counts and basic readings" {
  let lex = @yisheng.Lexicon::builtin()
  assert_eq(lex.tunes.length(), 78)
  let dong = @yisheng.lookup(lex, Pingshui, '东')
  assert_true(dong.length() > 0)
  assert_eq(dong[0].group, "上平一东")
  assert_true(@yisheng.is_ping(dong[0].tone))
  let kan = @yisheng.lookup(lex, Pingshui, '看')
  assert_eq(kan.length(), 2)
  let ting = @yisheng.lookup(lex, Cilin, '处')
  assert_true(ting.length() >= 1)
  assert_eq(ting[0].group, "第四部")
  assert_true(@yisheng.group_chars(lex, Pingshui, "上声三讲").length() == 5)
}

///|
test "common rhyme group intersects readings" {
  let lex = @yisheng.Lexicon::builtin()
  let chars = ['暮', '路', '处', '渡', '鹭']
  assert_eq(
    @yisheng.common_group(lex, Cilin, chars, Some(false)),
    Some("第四部"),
  )
  let chars2 = ['哀', '回', '来', '台', '杯']
  assert_eq(
    @yisheng.common_group(lex, Pingshui, chars2, Some(true)),
    Some("上平十灰"),
  )
}

///|
test "poem lines split on punctuation and newlines" {
  let lines = @yisheng.poem_lines(
    "床前明月光，疑是地上霜。\n举头望明月，低头思故乡。",
  )
  assert_eq(lines.length(), 4)
  assert_eq(lines[0], "床前明月光")
  assert_eq(lines[1], "疑是地上霜")
}

///|
test "every Pingshui group is internally consistent" {
  let lex = @yisheng.Lexicon::builtin()
  for group in @yisheng.group_names(lex, @yisheng.Pingshui) {
    let chars = @yisheng.group_chars(lex, @yisheng.Pingshui, group)
    let found = @yisheng.common_group(lex, @yisheng.Pingshui, chars, None)
    if found != Some(group) {
      let shown = match found {
        Some(g) => g
        None => "<none>"
      }
      println("group mismatch: " + group + " -> " + shown)
    }
    assert_eq(found, Some(group))
  }
}

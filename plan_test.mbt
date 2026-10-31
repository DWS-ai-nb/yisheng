///|
test "shi plan has the right line count and rhyme marks" {
  let plan = @yisheng.plan_shi(@yisheng.QiLv, 0)
  assert_eq(plan.lines.length(), 8)
  let mut rhymes = 0
  for l in plan.lines {
    if l.contains("韵") {
      rhymes = rhymes + 1
    }
  }
  // 首句入韵 + 七个韵句中的其余五个（第 3、5、7 句为出句）。
  assert_eq(rhymes, 5)
}

///|
test "ci plan exposes all builtin formats" {
  let lex = @yisheng.Lexicon::builtin()
  let plans = @yisheng.plan_ci(lex, "如梦令")
  assert_eq(plans.length(), 3)
  assert_true(plans[0].lines[0].contains("韵"))
}

///|
test "pingshui has 106 groups and a known rhyme" {
  let lex = @yisheng.Lexicon::builtin()
  assert_eq(@yisheng.group_names(lex, @yisheng.Pingshui).length(), 106)
  let chars = @yisheng.group_chars(lex, @yisheng.Pingshui, "上平十灰")
  let mut has_ai = false
  for c in chars {
    if c == '哀' {
      has_ai = true
    }
  }
  assert_true(has_ai)
}

///|
test "every builtin ci format is well formed" {
  let lex = @yisheng.Lexicon::builtin()
  for t in lex.tunes {
    assert_true(t.pattern.length() > 0)
    for c in t.pattern {
      assert_true(c == 'p' || c == 'z' || c == 'a')
    }
    for idx in t.rhymes {
      assert_true(idx >= 0 && idx < t.pattern.length())
    }
    assert_true(t.rhymes.length() > 0)
  }
}

///|
test "variant 2 plan matches the 登高 form" {
  let plan = @yisheng.plan_shi(@yisheng.QiLv, 2)
  assert_eq(plan.lines.length(), 8)
  assert_true(plan.title.contains("仄起首句入韵"))
  let mut rhymes = 0
  for line in plan.lines {
    if line.contains("韵") {
      rhymes = rhymes + 1
    }
  }
  assert_eq(rhymes, 5)
}

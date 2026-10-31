///|
test "如梦令 李清照 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "常记溪亭日暮，沉醉不知归路。兴尽晚回舟，误入藕花深处。争渡，争渡，惊起一滩鸥鹭。"
  let r = @yisheng.check_ci(lex, text, Some("如梦令"))
  if !r.ok {
    for i in r.issues {
      println(
        i.code +
        " " +
        i.line.to_string() +
        ":" +
        i.col.to_string() +
        " " +
        i.message +
        " " +
        i.expected +
        "/" +
        i.actual,
      )
    }
  }
  assert_true(r.ok)
}

///|
test "忆江南 白居易 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "江南好，风景旧曾谙。日出江花红胜火，春来江水绿如蓝。能不忆江南。"
  let r = @yisheng.check_ci(lex, text, Some("忆江南"))
  if !r.ok {
    for i in r.issues {
      println(
        i.code +
        " " +
        i.line.to_string() +
        ":" +
        i.col.to_string() +
        " " +
        i.message,
      )
    }
  }
  assert_true(r.ok)
}

///|
test "浣溪沙 晏殊 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "一曲新词酒一杯，去年天气旧亭台。夕阳西下几时回。无可奈何花落去，似曾相识燕归来。小园香径独徘徊。"
  let r = @yisheng.check_ci(lex, text, Some("浣溪沙"))
  if !r.ok {
    for i in r.issues {
      println(
        i.code +
        " " +
        i.line.to_string() +
        ":" +
        i.col.to_string() +
        " " +
        i.message,
      )
    }
  }
  assert_true(r.ok)
}

///|
test "wrong ci tone is reported" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "常来溪亭日暮，沉醉不知归路。兴尽晚回舟，误入藕花深处。争渡，争渡，惊起一滩鸥鹭。"
  let r = @yisheng.check_ci(lex, text, Some("如梦令"))
  assert_false(r.ok)
  let mut found = false
  for i in r.issues {
    if i.code == "CI_TONE" && i.line == 1 && i.col == 2 {
      found = true
    }
  }
  assert_true(found)
}

///|
test "wrong ci length is reported" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "常记溪亭日暮，沉醉不知归路。兴尽晚回舟，误入藕花深处。争渡，争渡，惊起一滩鸥"
  let r = @yisheng.check_ci(lex, text, Some("如梦令"))
  assert_false(r.ok)
  assert_eq(r.issues[0].code, "CI_LENGTH")
}

///|
test "identify ci picks 如梦令" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "常记溪亭日暮，沉醉不知归路。兴尽晚回舟，误入藕花深处。争渡，争渡，惊起一滩鸥鹭。"
  let ranked = @yisheng.identify_ci(lex, text)
  assert_true(ranked.length() > 0)
  let (name, _, _) = ranked[0]
  assert_eq(name, "如梦令")
}

///|
test "more canonical ci pass" {
  let lex = @yisheng.Lexicon::builtin()
  let cases = [
    (
      "虞美人", "春花秋月何时了，往事知多少。小楼昨夜又东风，故国不堪回首月明中。雕栏玉砌应犹在，只是朱颜改。问君能有几多愁，恰似一江春水向东流。",
    ),
    (
      "蝶恋花", "槛菊愁烟兰泣露，罗幕轻寒，燕子双飞去。明月不谙离恨苦，斜光到晓穿朱户。昨夜西风凋碧树，独上高楼，望尽天涯路。欲寄彩笺兼尺素，山长水阔知何处。",
    ),
    (
      "水调歌头", "明月几时有，把酒问青天。不知天上宫阙，今夕是何年。我欲乘风归去，又恐琼楼玉宇，高处不胜寒。起舞弄清影，何似在人间。转朱阁，低绮户，照无眠。不应有恨，何事长向别时圆。人有悲欢离合，月有阴晴圆缺，此事古难全。但愿人长久，千里共婵娟。",
    ),
  ]
  for c in cases {
    let (name, text) = c
    let r = @yisheng.check_ci(lex, text, Some(name))
    if !r.ok {
      println("FAILED " + name + " => " + r.template)
      for i in r.issues {
        println(
          "  " +
          i.code +
          " " +
          i.line.to_string() +
          ":" +
          i.col.to_string() +
          " " +
          i.expected +
          "/" +
          i.actual,
        )
      }
    }
    assert_true(r.ok)
  }
}

///|
test "七律 登高 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "风急天高猿啸哀，渚清沙白鸟飞回。无边落木萧萧下，不尽长江滚滚来。万里悲秋常作客，百年多病独登台。艰难苦恨繁霜鬓，潦倒新停浊酒杯。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_eq(r.form, "七律")
  assert_eq(r.rhyme, "上平十灰")
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
test "五律 春望 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "国破山河在，城春草木深。感时花溅泪，恨别鸟惊心。烽火连三月，家书抵万金。白头搔更短，浑欲不胜簪。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_eq(r.form, "五律")
  assert_true(r.ok)
}

///|
test "七绝 早发白帝城 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "朝辞白帝彩云间，千里江陵一日还。两岸猿声啼不住，轻舟已过万重山。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_eq(r.form, "七绝")
  assert_eq(r.rhyme, "上平十五删")
  assert_true(r.ok)
}

///|
test "五绝 登鹳雀楼 passes" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "白日依山尽，黄河入海流。欲穷千里目，更上一层楼。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_eq(r.form, "五绝")
  assert_true(r.ok)
}

///|
test "wrong tone is reported at the fixed position" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "朝辞白云彩云间，千里江陵一日还。两岸猿声啼不住，轻舟已过万重山。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_false(r.ok)
  let mut found = false
  for i in r.issues {
    if i.code == "SHI_TONE" && i.line == 1 && i.col == 4 {
      found = true
    }
  }
  assert_true(found)
}

///|
test "wrong rhyme is reported" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "朝辞白帝彩云间，千里江陵一日还。两岸猿声啼不住，轻舟已过万重天。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_false(r.ok)
  let mut found = false
  for i in r.issues {
    if i.code == "RHYME_MISMATCH" {
      found = true
    }
  }
  assert_true(found)
}

///|
test "wrong shape is rejected" {
  let lex = @yisheng.Lexicon::builtin()
  let r = @yisheng.check_shi(lex, "床前明月光", None)
  assert_false(r.ok)
  assert_eq(r.issues[0].code, "SHI_SHAPE")
}

///|
fn report_codes(r : @yisheng.Report) -> String {
  let sb = StringBuilder()
  for i in r.issues {
    sb.write_string(i.code)
    sb.write_string("(")
    sb.write_string(i.line.to_string())
    sb.write_string(":")
    sb.write_string(i.col.to_string())
    sb.write_string(") ")
  }
  sb.to_string()
}

///|
test "more canonical shi pass" {
  let lex = @yisheng.Lexicon::builtin()
  let poems = [
    "丞相祠堂何处寻，锦官城外柏森森。映阶碧草自春色，隔叶黄鹂空好音。三顾频烦天下计，两朝开济老臣心。出师未捷身先死，长使英雄泪满襟。",
    "远上寒山石径斜，白云生处有人家。停车坐爱枫林晚，霜叶红于二月花。",
    "众鸟高飞尽，孤云独去闲。相看两不厌，只有敬亭山。", "相见时难别亦难，东风无力百花残。春蚕到死丝方尽，蜡炬成灰泪始干。晓镜但愁云鬓改，夜吟应觉月光寒。蓬山此去无多路，青鸟殷勤为探看。",
    "空山新雨后，天气晚来秋。明月松间照，清泉石上流。竹喧归浣女，莲动下渔舟。随意春芳歇，王孙自可留。",
  ]
  for p in poems {
    let r = @yisheng.check_shi(lex, p, None)
    if !r.ok {
      println(
        "FAILED: " +
        p +
        " => " +
        r.form +
        "·" +
        r.template +
        " " +
        report_codes(r),
      )
      for v in r.lines {
        println("  " + v.text + " | " + v.pattern + " | " + v.actual)
      }
    }
    assert_true(r.ok)
  }
}

///|
test "孤平 is detected" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "白日依山尽，夜风落叶清。欲穷千里目，独坐一灯明。"
  let r = @yisheng.check_shi(lex, text, None)
  let mut found = false
  for i in r.issues {
    if i.code == "GU_PING" && i.line == 2 {
      found = true
    }
  }
  assert_true(found)
  assert_false(r.ok)
}

///|
test "三平调 is detected" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "白日依山尽，清风落木清。欲穷千里目，独坐虚窗明。"
  let r = @yisheng.check_shi(lex, text, None)
  let mut found = false
  for i in r.issues {
    if i.code == "SAN_PING" && i.line == 4 {
      found = true
    }
  }
  assert_true(found)
  assert_false(r.ok)
}

///|
test "unknown character is a warning, not a hard failure" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "白日依山尽，黄河入海流。欲穷千里目，更上龘层楼。"
  let r = @yisheng.check_shi(lex, text, None)
  let mut warned = false
  for i in r.issues {
    if i.code == "UNKNOWN_CHAR" {
      warned = true
    }
  }
  assert_true(warned)
}

///|
test "polyphonic lookup keeps both readings" {
  let lex = @yisheng.Lexicon::builtin()
  let readings = @yisheng.lookup(lex, @yisheng.Pingshui, '看')
  assert_eq(readings.length(), 2)
  let mut ping = false
  let mut ze = false
  for r in readings {
    if @yisheng.is_ping(r.tone) {
      ping = true
    } else {
      ze = true
    }
  }
  assert_true(ping && ze)
}

///|
test "unknown first rhyme does not crash" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "朝辞白帝彩云龘，千里江陵一日还。两岸猿声啼不住，轻舟已过万重天。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_false(r.ok)
  let mut warned = false
  for i in r.issues {
    if i.code == "UNKNOWN_CHAR" {
      warned = true
    }
  }
  assert_true(warned)
}

///|
test "student example reports both errors in one run" {
  let lex = @yisheng.Lexicon::builtin()
  let text = "朝辞白云彩云间，千里江陵一日还。两岸猿声啼不住，轻舟已过万重天。"
  let r = @yisheng.check_shi(lex, text, None)
  assert_false(r.ok)
  let mut tone = false
  let mut rhyme = false
  for i in r.issues {
    if i.code == "SHI_TONE" && i.line == 1 && i.col == 4 {
      tone = true
    }
    if i.code == "RHYME_MISMATCH" && i.line == 4 && i.col == 7 {
      rhyme = true
    }
  }
  assert_true(tone)
  assert_true(rhyme)
}

///|
/// Templates for composition (`plan`) and rhyme-book queries (`rhyme`).
pub struct Plan {
  title : String
  lines : Array[String]
}

///|
fn mark_pattern(pattern : String, rhyme : Bool) -> String {
  let sb = StringBuilder()
  let chars = pattern.to_array()
  for i in 0..<chars.length() {
    sb.write_char(
      match chars[i] {
        'p' => '平'
        'z' => '仄'
        _ => '中'
      },
    )
  }
  if rhyme {
    sb.write_string("（韵）")
  }
  sb.to_string()
}

///|
pub fn plan_shi(form : ShiForm, variant : Int32) -> Plan {
  let variants = patterns_for(form)
  let v = if variant < 0 || variant > 3 { 0 } else { variant }
  let pattern = variants[v]
  let lines : Array[String] = []
  for p in pattern {
    let rhyme = p.to_array()[p.length() - 1] == 'p'
    lines.push(mark_pattern(p, rhyme))
  }
  { title: shi_form_label(form) + "·" + variant_label(v), lines, }
}

///|
pub fn plan_ci(lex : Lexicon, name : String) -> Array[Plan] {
  let out : Array[Plan] = []
  for t in lex.tunes {
    if t.name == name {
      let marked = StringBuilder()
      let chars = t.pattern.to_array()
      for i in 0..<chars.length() {
        marked.write_char(
          match chars[i] {
            'p' => '平'
            'z' => '仄'
            _ => '中'
          },
        )
        let mut is_rhyme = false
        for r in t.rhymes {
          if r == i {
            is_rhyme = true
          }
        }
        if is_rhyme {
          marked.write_char('韵')
        }
        if i % 10 == 9 {
          marked.write_char(' ')
        }
      }
      out.push({
        title: t.name + "·" + t.sketch + "（" + t.author + "）",
        lines: [marked.to_string()],
      })
    }
  }
  out
}

///|
pub fn form_names() -> Array[String] {
  ["五绝", "七绝", "五律", "七律"]
}

///|
pub fn builtin_tune_names(lex : Lexicon) -> Array[String] {
  let out : Array[String] = []
  for t in lex.tunes {
    let mut seen = false
    for n in out {
      if n == t.name {
        seen = true
      }
    }
    if !seen {
      out.push(t.name)
    }
  }
  out
}

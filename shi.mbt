///|
/// Regulated verse (近体诗) templates and checker.
///
/// The four-line templates below are the standard 平起/仄起 × 首句入韵/不入韵
/// set. A regulated eight-line poem (律诗) is the four-line template followed by
/// the non-rhyming variant of the same 起式, because line 5 must 粘 line 4.
pub(all) enum ShiForm {
  WuJue
  QiJue
  WuLv
  QiLv
}

///|
pub fn shi_form_label(form : ShiForm) -> String {
  match form {
    WuJue => "五绝"
    QiJue => "七绝"
    WuLv => "五律"
    QiLv => "七律"
  }
}

///|
fn shi_width(form : ShiForm) -> Int32 {
  match form {
    WuJue | WuLv => 5
    QiJue | QiLv => 7
  }
}

///|
fn shi_is_lv(form : ShiForm) -> Bool {
  match form {
    WuJue | QiJue => false
    WuLv | QiLv => true
  }
}

///|
fn wu_ju_patterns() -> Array[Array[String]] {
  [
    // 平起首句入韵
    ["ppzzp", "zzzpp", "zzppz", "ppzzp"],
    // 平起首句不入韵
    ["pppzz", "zzzpp", "zzppz", "ppzzp"],
    // 仄起首句入韵
    ["zzzpp", "ppzzp", "pppzz", "zzzpp"],
    // 仄起首句不入韵
    ["zzppz", "ppzzp", "pppzz", "zzzpp"],
  ]
}

///|
fn qi_ju_patterns() -> Array[Array[String]] {
  [
    // 平起首句入韵
    ["ppzzzpp", "zzppzzp", "zzpppzz", "ppzzzpp"],
    // 平起首句不入韵
    ["ppzzppz", "zzppzzp", "zzpppzz", "ppzzzpp"],
    // 仄起首句入韵
    ["zzppzzp", "ppzzzpp", "ppzzppz", "zzppzzp"],
    // 仄起首句不入韵
    ["zzpppzz", "ppzzzpp", "ppzzppz", "zzppzzp"],
  ]
}

///|
fn variant_label(index : Int32) -> String {
  match index {
    0 => "平起首句入韵"
    1 => "平起首句不入韵"
    2 => "仄起首句入韵"
    _ => "仄起首句不入韵"
  }
}

///|
/// 4 variants, each with 4 or 8 lines of 'p' / 'z' requirement.
fn patterns_for(form : ShiForm) -> Array[Array[String]] {
  let base = match form {
    WuJue | WuLv => wu_ju_patterns()
    QiJue | QiLv => qi_ju_patterns()
  }
  if !shi_is_lv(form) {
    return base
  }
  let out : Array[Array[String]] = []
  for v in 0..<4 {
    // Same 起式, but the second half is the 首句不入韵 template.
    let tail_variant = if v == 0 || v == 1 { 1 } else { 3 }
    let lines : Array[String] = []
    for i in 0..<4 {
      lines.push(base[v][i])
    }
    for i in 0..<4 {
      lines.push(base[tail_variant][i])
    }
    out.push(lines)
  }
  out
}

///|
/// Strict (二四六分明) positions. Positions 1/3/5 are flexible, but the last
/// character of a line is always fixed because it decides rhyme.
fn strict_positions(width : Int32) -> Array[Int32] {
  if width == 5 {
    [1, 3, 4]
  } else {
    [1, 3, 5, 6]
  }
}

///|
fn is_strict(width : Int32, pos : Int32) -> Bool {
  for p in strict_positions(width) {
    if p == pos {
      return true
    }
  }
  false
}

///|
/// Tone candidates for one character, restricted to an expected tone when
/// possible. Returns all distinct tones; an unknown character yields none.
fn tone_candidates(
  lex : Lexicon,
  ch : Char,
  expected : Char,
  restrict : Bool,
) -> Array[Char] {
  let out : Array[Char] = []
  for r in lookup(lex, Pingshui, ch) {
    let code = tone_code(r.tone)
    let ok = if restrict && expected != 'a' { code == expected } else { true }
    if ok {
      let mut seen = false
      for c in out {
        if c == code {
          seen = true
        }
      }
      if !seen {
        out.push(code)
      }
    }
  }
  out
}

///|
priv struct Assignment {
  hard : Int32
  warn : Int32
  tones : Array[Char]
}

///|
fn exception_penalty(tones : Array[Char], pattern : String) -> (Int32, Int32) {
  let n = tones.length()
  let last = pattern[n - 1]
  let mut hard = 0
  let mut warn = 0
  if last == 'p' {
    // 三平调: the three characters before the rhyme must not all be 平.
    if n >= 3 &&
      tones[n - 1] == 'p' &&
      tones[n - 2] == 'p' &&
      tones[n - 3] == 'p' {
      hard = hard + 1
    }
    // 孤平: 平平仄仄平 / 仄仄平平仄仄平 with the safeguard character 仄.
    if n == 5 && pattern == "ppzzp" && tones[0] == 'z' && tones[2] == 'z' {
      hard = hard + 1
    }
    if n == 7 && pattern == "zzppzzp" && tones[2] == 'z' && tones[4] == 'z' {
      hard = hard + 1
    }
    // 三仄尾 is avoided but not a hard fault in most teaching traditions.
  } else if n >= 3 &&
    tones[n - 1] == 'z' &&
    tones[n - 2] == 'z' &&
    tones[n - 3] == 'z' {
    warn = warn + 1
  }
  (hard, warn)
}

///|
fn search_assignment(
  pos : Int32,
  choices : Array[Array[Char]],
  current : Array[Char],
  pattern : String,
) -> Assignment {
  if pos == choices.length() {
    let (hard, warn) = exception_penalty(current, pattern)
    return { hard, warn, tones: current.copy(), }
  }
  let mut best : Assignment = { hard: 99, warn: 99, tones: [], }
  let mut first = true
  for tone in choices[pos] {
    current[pos] = tone
    let candidate = search_assignment(pos + 1, choices, current, pattern)
    if first ||
      candidate.hard < best.hard ||
      (candidate.hard == best.hard && candidate.warn < best.warn) {
      best = candidate
      first = false
    }
  }
  best
}

///|
fn make_issue(
  code : String,
  severity : Severity,
  line : Int32,
  col : Int32,
  message : String,
  expected : String,
  actual : String,
) -> Issue {
  { code, severity, line, col, message, expected, actual, }
}

///|
fn analyze_line(
  lex : Lexicon,
  text : String,
  pattern : String,
  line_no : Int32,
  issues : Array[Issue],
) -> LineView {
  let chars = text.to_array()
  let n = chars.length()
  let width = n
  let choices : Array[Array[Char]] = []
  let unknown_cols : Array[Int32] = []
  for i in 0..<n {
    let expected = pattern.to_array()[i]
    let strict = is_strict(width, i)
    let mut cands = tone_candidates(lex, chars[i], expected, strict)
    if cands.length() == 0 {
      if lookup(lex, Pingshui, chars[i]).length() == 0 {
        unknown_cols.push(i + 1)
        cands = ['?']
      } else {
        // No reading satisfies this fixed position: keep all readings so the
        // mismatch can be reported against the chosen one.
        cands = tone_candidates(lex, chars[i], expected, false)
      }
    }
    choices.push(cands)
  }
  let current : Array[Char] = []
  for _ in 0..<n {
    current.push('?')
  }
  let assignment = search_assignment(0, choices, current, pattern)
  let tones = if assignment.tones.length() == n {
    assignment.tones
  } else {
    let fallback : Array[Char] = []
    for i in 0..<n {
      fallback.push(if choices[i].length() > 0 { choices[i][0] } else { '?' })
    }
    fallback
  }

  let bad_cols : Array[Int32] = []
  for i in 0..<n {
    let expected = pattern.to_array()[i]
    if is_strict(width, i) &&
      tones[i] != '?' &&
      tones[i] != expected &&
      expected != 'a' {
      bad_cols.push(i + 1)
      issues.push(
        make_issue(
          "SHI_TONE",
          Error,
          line_no,
          i + 1,
          "第" +
          (i + 1).to_string() +
          "字应为" +
          tone_label(if expected == 'p' { Ping } else { Ze }) +
          "，实为" +
          tone_label(if tones[i] == 'p' { Ping } else { Ze }),
          tone_label(if expected == 'p' { Ping } else { Ze }),
          tone_label(if tones[i] == 'p' { Ping } else { Ze }),
        ),
      )
    }
  }
  for col in unknown_cols {
    issues.push(
      make_issue(
        "UNKNOWN_CHAR",
        Warning,
        line_no,
        col,
        "该字不在平水韵表中，按未知处理，未参与平仄判定",
        "",
        "",
      ),
    )
  }
  let (hard, warn) = exception_penalty(tones, pattern)
  if hard > 0 {
    if tones[n - 1] == 'p' &&
      n >= 3 &&
      tones[n - 2] == 'p' &&
      tones[n - 3] == 'p' {
      issues.push(
        make_issue(
          "SAN_PING",
          Error,
          line_no,
          n,
          "三平调：韵脚连用三个平声",
          "末三字不全平",
          "平平平",
        ),
      )
    } else {
      issues.push(
        make_issue(
          "GU_PING",
          Error,
          line_no,
          0,
          "孤平：韵句除韵脚外只剩一个平声字",
          "",
          "",
        ),
      )
    }
  }
  if warn > 0 {
    issues.push(
      make_issue(
        "SAN_ZE",
        Warning,
        line_no,
        n,
        "三仄尾：出句末三字全仄，读来拗口（非硬伤）",
        "末三字不全仄",
        "仄仄仄",
      ),
    )
  }
  let actual_sb = StringBuilder()
  for t in tones {
    actual_sb.write_char(t)
  }
  { text, pattern, actual: actual_sb.to_string(), bad_cols, }
}

///|
fn count_mismatches(
  lex : Lexicon,
  lines : Array[String],
  pattern : Array[String],
) -> Int32 {
  let mut score = 0
  for i in 0..<lines.length() {
    let chars = lines[i].to_array()
    for pos in strict_positions(chars.length()) {
      if pos < chars.length() && pos < pattern[i].length() {
        let expected = pattern[i].to_array()[pos]
        if expected != 'a' {
          let ok = tone_candidates(lex, chars[pos], expected, true).length() > 0
          let unknown = lookup(lex, Pingshui, chars[pos]).length() == 0
          if !ok && !unknown {
            score = score + 1
          }
        }
      }
    }
    // A rhyme line must end in a 平 reading.
    if pattern[i].to_array()[chars.length() - 1] == 'p' {
      let last = chars[chars.length() - 1]
      let ping = lookup(lex, Pingshui, last)
      let mut has_ping = false
      for r in ping {
        if is_ping(r.tone) {
          has_ping = true
        }
      }
      if !has_ping && ping.length() > 0 {
        score = score + 2
      }
    }
  }
  score
}

///|
fn check_rhyme(
  lex : Lexicon,
  lines : Array[String],
  pattern : Array[String],
  issues : Array[Issue],
) -> String {
  let rhyme_lines : Array[Int32] = []
  for i in 0..<lines.length() {
    if pattern[i].to_array()[lines[i].to_array().length() - 1] == 'p' {
      rhyme_lines.push(i)
    }
  }
  if rhyme_lines.length() == 0 {
    return ""
  }
  let rhyme_chars : Array[Char] = []
  for i in rhyme_lines {
    let cs = lines[i].to_array()
    rhyme_chars.push(cs[cs.length() - 1])
  }
  match common_group(lex, Pingshui, rhyme_chars, Some(true)) {
    Some(group) => group
    None => {
      let first = rhyme_chars[0]
      let first_groups = groups_of(lex, Pingshui, first)
      for k in 1..<rhyme_chars.length() {
        let ch = rhyme_chars[k]
        let gs = groups_of(lex, Pingshui, ch)
        let mut overlap = false
        for g in gs {
          for h in first_groups {
            if g == h {
              overlap = true
            }
          }
        }
        // Only 平声 groups count for a regulated-verse rhyme.
        if !overlap {
          issues.push(
            make_issue(
              "RHYME_MISMATCH",
              Error,
              rhyme_lines[k] + 1,
              lines[rhyme_lines[k]].to_array().length(),
              "韵脚「" +
              string_of_chars([ch]) +
              "」与首句「" +
              string_of_chars([first]) +
              "」不押同一韵部",
              first_groups[0],
              if gs.length() > 0 {
                gs[0]
              } else {
                "未知"
              },
            ),
          )
        }
      }
      ""
    }
  }
}

///|
/// Check a regulated verse. When `form` is None the shape (5/7 characters,
/// 4/8 lines) decides the form, and the four 起式 are scored to pick the
/// closest template.
pub fn check_shi(lex : Lexicon, text : String, form : ShiForm?) -> Report {
  let lines = poem_lines(text)
  let report = empty_report()
  let width = if lines.length() > 0 { lines[0].to_array().length() } else { 0 }
  let resolved : ShiForm? = match form {
    Some(f) => Some(f)
    None => {
      let n = lines.length()
      let mut uniform = n == 4 || n == 8
      for l in lines {
        if l.to_array().length() != width {
          uniform = false
        }
      }
      if !uniform {
        None
      } else if width == 5 {
        Some(if n == 4 { WuJue } else { WuLv })
      } else if width == 7 {
        Some(if n == 4 { QiJue } else { QiLv })
      } else {
        None
      }
    }
  }
  match resolved {
    None => {
      report.ok = false
      report.form = "未识别"
      report.issues.push(
        make_issue(
          "SHI_SHAPE",
          Error,
          0,
          0,
          "无法识别诗体：需要 4 句或 8 句，且每句 5 或 7 个字",
          "五/七言绝句或律诗",
          lines.length().to_string() + " 句",
        ),
      )
      report
    }
    Some(f) => {
      let expected_width = shi_width(f)
      let expected_lines = if shi_is_lv(f) { 8 } else { 4 }
      if lines.length() != expected_lines || width != expected_width {
        report.ok = false
        report.form = shi_form_label(f)
        report.issues.push(
          make_issue(
            "SHI_SHAPE",
            Error,
            0,
            0,
            "句数或字数与所选诗体不符",
            expected_lines.to_string() +
            " 句，每句 " +
            expected_width.to_string() +
            " 字",
            lines.length().to_string() +
            " 句，每句 " +
            width.to_string() +
            " 字",
          ),
        )
        return report
      }
      let variants = patterns_for(f)
      let mut best = 0
      let mut best_score = 1_000_000
      for v in 0..<4 {
        let score = count_mismatches(lex, lines, variants[v])
        if score < best_score {
          best_score = score
          best = v
        }
      }
      let pattern = variants[best]
      report.form = shi_form_label(f)
      report.template = variant_label(best)
      let issues : Array[Issue] = []
      let views : Array[LineView] = []
      for i in 0..<lines.length() {
        views.push(analyze_line(lex, lines[i], pattern[i], i + 1, issues))
      }
      let rhyme = check_rhyme(lex, lines, pattern, issues)
      report.rhyme = rhyme
      if rhyme.length() > 0 {
        report.notes.push("押韵：" + rhyme + "（平水韵）")
      }
      report.lines = views
      report.issues = issues
      let mut ok = true
      for issue in issues {
        match issue.severity {
          Error => ok = false
          _ => ()
        }
      }
      report.ok = ok
      report
    }
  }
}

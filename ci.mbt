///|
/// Ci (词) checking against the curated 词谱 table.
///
/// The table stores one flat tone pattern per format plus the offsets that must
/// rhyme. Input punctuation and line breaks are ignored for matching, but are
/// preserved for reporting.
fn flatten(lines : Array[String]) -> String {
  let sb = StringBuilder()
  for l in lines {
    sb.write_string(l)
  }
  sb.to_string()
}

///|
fn find_tune_formats(lex : Lexicon, name : String) -> Array[CiTune] {
  let out : Array[CiTune] = []
  for t in lex.tunes {
    if t.name == name {
      out.push(t)
    }
  }
  out
}

///|
/// Tone fit for one ci position. Returns 0 for a match, 1 for a mismatch and
/// 0 for an unknown character (reported separately as a warning).
fn ci_tone_mismatch(lex : Lexicon, ch : Char, expected : Char) -> Int32 {
  if expected == 'a' {
    return 0
  }
  let readings = lookup(lex, Cilin, ch)
  if readings.length() == 0 {
    return 0
  }
  for r in readings {
    let code = tone_code(r.tone)
    if code == expected {
      return 0
    }
  }
  1
}

///|
fn ci_score(lex : Lexicon, flat : String, tune : CiTune) -> Int32 {
  let chars = flat.to_array()
  if chars.length() != tune.pattern.length() {
    let diff = if chars.length() > tune.pattern.length() {
      chars.length() - tune.pattern.length()
    } else {
      tune.pattern.length() - chars.length()
    }
    return 1000 + diff
  }
  let pattern = tune.pattern.to_array()
  let mut score = 0
  for i in 0..<chars.length() {
    score = score + ci_tone_mismatch(lex, chars[i], pattern[i])
  }
  for idx in tune.rhymes {
    if idx < chars.length() {
      let expected = pattern[idx]
      let groups = filtered_groups(lex, chars[idx], expected)
      if groups.length() == 0 {
        score = score + 3
      }
    }
  }
  score
}

///|
/// Rhyme-group candidates for a rhyme position, keeping 入声 separate.
fn filtered_groups(lex : Lexicon, ch : Char, expected : Char) -> Array[String] {
  let want_ping = expected == 'p'
  let readings = lookup(lex, Cilin, ch)
  let out : Array[String] = []
  for r in readings {
    let tone_ok = is_ping(r.tone) == want_ping
    if tone_ok && r.tone_class != "入" {
      out.push(r.group)
    }
  }
  if out.length() > 0 {
    return out
  }
  // No 上/去 reading: fall back to 入声 (词牌 入声韵).
  for r in readings {
    if r.tone_class == "入" {
      out.push(r.group)
    }
  }
  out
}

///|
priv struct CiMatch {
  tune : CiTune
  score : Int32
}

///|
pub fn identify_ci(
  lex : Lexicon,
  text : String,
) -> Array[(String, Int32, String)] {
  let lines = poem_lines(text)
  let flat = flatten(lines)
  let matches : Array[CiMatch] = []
  for t in lex.tunes {
    matches.push({ tune: t, score: ci_score(lex, flat, t), })
  }
  // Insertion sort: small table, deterministic order.
  let sorted : Array[CiMatch] = []
  for m in matches {
    let mut at = sorted.length()
    let mut i = 0
    while i < sorted.length() {
      if m.score < sorted[i].score {
        at = i
        break
      }
      i = i + 1
    }
    sorted.insert(at, m)
  }
  let out : Array[(String, Int32, String)] = []
  for m in sorted {
    let mut duplicate = false
    for item in out {
      let (name, _, _) = item
      if name == m.tune.name {
        duplicate = true
      }
    }
    if !duplicate {
      out.push((m.tune.name, m.score, m.tune.sketch))
    }
    if out.length() == 5 {
      break
    }
  }
  out
}

///|
fn flat_to_line_col(offsets : Array[Int32], index : Int32) -> (Int32, Int32) {
  let mut line = 0
  let mut i = 0
  while i < offsets.length() {
    if offsets[i] <= index {
      line = i
    }
    i = i + 1
  }
  (line, index - offsets[line] + 1)
}

///|
fn report_ci(
  lex : Lexicon,
  lines : Array[String],
  tune : CiTune,
  exact : Bool,
) -> Report {
  let report = empty_report()
  report.form = tune.name + "（" + tune.sketch + "）"
  report.template = tune.name + "·" + tune.author
  let chars = flatten(lines).to_array()
  let pattern = tune.pattern.to_array()
  let offsets : Array[Int32] = []
  let mut acc = 0
  for l in lines {
    offsets.push(acc)
    acc = acc + l.to_array().length()
  }
  let issues : Array[Issue] = []
  if !exact {
    report.ok = false
    issues.push(
      make_issue(
        "CI_LENGTH",
        Error,
        0,
        0,
        "字数与词谱不符",
        tune.pattern.length().to_string() + " 字",
        chars.length().to_string() + " 字",
      ),
    )
    // Still show what can be compared.
  }
  let views : Array[LineView] = []
  let n = if chars.length() < pattern.length() {
    chars.length()
  } else {
    pattern.length()
  }
  let mut line_start = 0
  for li in 0..<lines.length() {
    let len = lines[li].to_array().length()
    let view_pattern = StringBuilder()
    let view_actual = StringBuilder()
    let bad_cols : Array[Int32] = []
    for k in 0..<len {
      let idx = line_start + k
      if idx < n {
        let p = pattern[idx]
        view_pattern.write_char(p)
        let readings = lookup(lex, Cilin, chars[idx])
        if readings.length() == 0 {
          view_actual.write_char('?')
          issues.push(
            make_issue(
              "UNKNOWN_CHAR",
              Warning,
              li + 1,
              k + 1,
              "该字不在词林正韵表中",
              "",
              "",
            ),
          )
        } else {
          let mut chosen = '?'
          for r in readings {
            if p == 'a' || tone_code(r.tone) == p {
              chosen = tone_code(r.tone)
              break
            }
          }
          if chosen == '?' {
            chosen = tone_code(readings[0].tone)
          }
          view_actual.write_char(chosen)
          if p != 'a' && chosen != p {
            bad_cols.push(k + 1)
            issues.push(
              make_issue(
                "CI_TONE",
                Error,
                li + 1,
                k + 1,
                "第" +
                (k + 1).to_string() +
                "字应为" +
                (if p == 'p' { "平" } else { "仄" }) +
                "，实为" +
                (if chosen == 'p' { "平" } else { "仄" }),
                if p == 'p' {
                  "平"
                } else {
                  "仄"
                },
                if chosen == 'p' {
                  "平"
                } else {
                  "仄"
                },
              ),
            )
          }
        }
      }
    }
    line_start = line_start + len
    views.push({
      text: lines[li],
      pattern: view_pattern.to_string(),
      actual: view_actual.to_string(),
      bad_cols,
    })
  }
  // Rhyme segments: split where the expected tone changes.
  let segments : Array[Array[Int32]] = []
  let mut current : Array[Int32] = []
  let mut last_tone = 'a'
  for idx in tune.rhymes {
    if idx >= n {
      continue
    }
    let tone = pattern[idx]
    if current.length() > 0 && tone != last_tone {
      segments.push(current)
      current = []
    }
    current.push(idx)
    last_tone = tone
  }
  if current.length() > 0 {
    segments.push(current)
  }
  let rhyme_notes : Array[String] = []
  for seg in segments {
    if seg.length() == 0 {
      continue
    }
    let expected = pattern[seg[0]]
    let seg_chars : Array[Char] = []
    for idx in seg {
      seg_chars.push(chars[idx])
    }
    let common = common_ci_group(lex, seg_chars, expected)
    let common_pingshui = if common == None {
      common_group(lex, Pingshui, seg_chars, Some(expected == 'p'))
    } else {
      None
    }
    match common {
      Some(g) =>
        rhyme_notes.push(
          g + "（" + (if expected == 'p' { "平" } else { "仄" }) + "）",
        )
      None =>
        match common_pingshui {
          Some(g) =>
            rhyme_notes.push(
              g +
              "（平水韵同部，词韵跨部通押；" +
              (if expected == 'p' { "平" } else { "仄" }) +
              "）",
            )
          None =>
            for k in 0..<seg.length() {
              let (line, col) = flat_to_line_col(offsets, seg[k])
              let gs = filtered_groups(lex, chars[seg[k]], expected)
              issues.push(
                make_issue(
                  "CI_RHYME",
                  Error,
                  line + 1,
                  col,
                  "韵脚不在同一韵部（同段内）",
                  if gs.length() > 0 {
                    gs[0]
                  } else {
                    "未知"
                  },
                  "",
                ),
              )
            }
        }
    }
  }
  for note in rhyme_notes {
    report.notes.push("用韵：" + note)
  }
  report.lines = views
  report.issues = issues
  let mut ok = report.ok
  for issue in issues {
    match issue.severity {
      Error => ok = false
      _ => ()
    }
  }
  report.ok = ok
  report
}

///|
/// Intersect rhyme groups within one ci rhyme segment. 入声 readings are kept
/// apart from 上/去 so a 入声韵 词牌 is not accepted with an 上声 rhyme.
fn common_ci_group(
  lex : Lexicon,
  chars : Array[Char],
  expected : Char,
) -> String? {
  if chars.length() == 0 {
    return None
  }
  let want_ping = expected == 'p'
  let mut candidates = filtered_groups(lex, chars[0], expected)
  let mut i = 1
  while i < chars.length() {
    let next : Array[String] = []
    let gs = filtered_groups(lex, chars[i], expected)
    for g in candidates {
      for h in gs {
        if g == h {
          next.push(g)
          break
        }
      }
    }
    candidates = next
    i = i + 1
  }
  let mut best : String? = None
  for g in candidates {
    match best {
      None => best = Some(g)
      Some(b) => if g < b { best = Some(g) }
    }
  }
  let _ = want_ping
  best
}

///|
pub fn check_ci(lex : Lexicon, text : String, name : String?) -> Report {
  let lines = poem_lines(text)
  let flat = flatten(lines)
  match name {
    None => {
      let ranked = identify_ci(lex, text)
      if ranked.length() == 0 {
        let report = empty_report()
        report.ok = false
        report.form = "未识别"
        report.issues.push(
          make_issue(
            "CI_IDENTIFY",
            Error,
            0,
            0,
            "没有匹配的词牌格式",
            "",
            "",
          ),
        )
        return report
      }
      let (best_name, best_score, _) = ranked[0]
      let formats = find_tune_formats(lex, best_name)
      let mut chosen = formats[0]
      let mut best = 1_000_000
      for t in formats {
        let s = ci_score(lex, flat, t)
        if s < best {
          best = s
          chosen = t
        }
      }
      let report = report_ci(lex, lines, chosen, best < 1000)
      report.notes.push(
        "词牌按格律最接近匹配：" +
        best_name +
        "（差异 " +
        best_score.to_string() +
        "）",
      )
      report
    }
    Some(wanted) => {
      let formats = find_tune_formats(lex, wanted)
      if formats.length() == 0 {
        let report = empty_report()
        report.ok = false
        report.form = wanted
        report.issues.push(
          make_issue(
            "CI_UNKNOWN_TUNE",
            Error,
            0,
            0,
            "内置词谱中没有该词牌",
            wanted,
            "",
          ),
        )
        return report
      }
      let mut chosen = formats[0]
      let mut best = 1_000_000
      for t in formats {
        let s = ci_score(lex, flat, t)
        if s < best {
          best = s
          chosen = t
        }
      }
      report_ci(lex, lines, chosen, best < 1000)
    }
  }
}

///|
/// Lexicon construction and lookup.
///
/// Two independent rhyme books are kept:
///   * 平水韵 (106 groups) for regulated verse (近体诗);
///   * 词林正韵 (19 parts) for ci.
/// Mixing them would silently accept wrong rhymes, so the API always takes an
/// explicit `RhymeSystem`.
fn add_reading(
  map : Map[Char, Array[Reading]],
  ch : Char,
  reading : Reading,
) -> Unit {
  match map.get(ch) {
    Some(existing) => {
      // The upstream tables occasionally repeat a character inside one group.
      let mut duplicate = false
      for r in existing {
        if r.group == reading.group && r.tone_class == reading.tone_class {
          duplicate = true
        }
      }
      if !duplicate {
        existing.push(reading)
      }
    }
    None => map.set(ch, [reading])
  }
}

///|
fn add_group_char(
  map : Map[String, Array[Char]],
  group : String,
  ch : Char,
) -> Unit {
  match map.get(group) {
    Some(existing) => existing.push(ch)
    None => map.set(group, [ch])
  }
}

///|
fn parse_pingshui(
  readings : Map[Char, Array[Reading]],
  groups : Map[String, Array[Char]],
  names : Array[String],
) -> Unit {
  for line in split_on(PINGSHUI_DATA, '\n') {
    if line.length() == 0 {
      continue
    }
    let parts = split_on(line, '\t')
    if parts.length() < 2 {
      continue
    }
    let group = parts[0]
    let chars = parts[1]
    let mut known = false
    for n in names {
      if n == group {
        known = true
      }
    }
    if !known {
      names.push(group)
    }
    let tone_class = if has_prefix(group, "上平") ||
      has_prefix(group, "下平") {
      "平"
    } else if has_prefix(group, "上声") {
      "上"
    } else if has_prefix(group, "去声") {
      "去"
    } else {
      "入"
    }
    let tone = if tone_class == "平" { Ping } else { Ze }
    for ch in chars {
      add_reading(readings, ch, { tone, group, tone_class, })
      add_group_char(groups, group, ch)
    }
  }
}

///|
fn parse_cilin(
  readings : Map[Char, Array[Reading]],
  groups : Map[String, Array[Char]],
  names : Array[String],
) -> Unit {
  for line in split_on(CILIN_DATA, '\n') {
    if line.length() == 0 {
      continue
    }
    let parts = split_on(line, '\t')
    if parts.length() < 3 {
      continue
    }
    let group = parts[0]
    let mut known = false
    for n in names {
      if n == group {
        known = true
      }
    }
    if !known {
      names.push(group)
    }
    let tone_name = parts[1]
    let chars = parts[2]
    let tone_class = if tone_name == "平声" {
      "平"
    } else if tone_name == "上声" {
      "上"
    } else if tone_name == "去声" {
      "去"
    } else {
      "入"
    }
    let tone = if tone_class == "平" { Ping } else { Ze }
    for ch in chars {
      add_reading(readings, ch, { tone, group, tone_class, })
      add_group_char(groups, group, ch)
    }
  }
}

///|
fn parse_tunes() -> Array[CiTune] {
  let out : Array[CiTune] = []
  for line in split_on(CITUNES_DATA, '\n') {
    if line.length() == 0 {
      continue
    }
    let parts = split_on(line, '\t')
    if parts.length() < 5 {
      continue
    }
    let rhymes : Array[Int32] = []
    for piece in split_on(parts[4], ',') {
      match parse_int_opt(piece) {
        Some(n) => rhymes.push(n)
        None => ()
      }
    }
    out.push({
      name: parts[0],
      sketch: parts[1],
      author: parts[2],
      pattern: parts[3],
      rhymes,
    })
  }
  out
}

///|
pub fn Lexicon::builtin() -> Lexicon {
  let pingshui : Map[Char, Array[Reading]] = Map([])
  let pingshui_groups : Map[String, Array[Char]] = Map([])
  let cilin : Map[Char, Array[Reading]] = Map([])
  let cilin_groups : Map[String, Array[Char]] = Map([])
  let pingshui_names : Array[String] = []
  let cilin_names : Array[String] = []
  parse_pingshui(pingshui, pingshui_groups, pingshui_names)
  parse_cilin(cilin, cilin_groups, cilin_names)
  {
    pingshui,
    cilin,
    pingshui_groups,
    cilin_groups,
    pingshui_names,
    cilin_names,
    tunes: parse_tunes(),
  }
}

///|
pub fn lookup(lex : Lexicon, system : RhymeSystem, ch : Char) -> Array[Reading] {
  let table = match system {
    Pingshui => lex.pingshui
    Cilin => lex.cilin
  }
  match table.get(ch) {
    Some(rs) => rs
    None => []
  }
}

///|
pub fn group_names(lex : Lexicon, system : RhymeSystem) -> Array[String] {
  match system {
    Pingshui => lex.pingshui_names
    Cilin => lex.cilin_names
  }
}

///|
pub fn group_chars(
  lex : Lexicon,
  system : RhymeSystem,
  group : String,
) -> Array[Char] {
  let table = match system {
    Pingshui => lex.pingshui_groups
    Cilin => lex.cilin_groups
  }
  match table.get(group) {
    Some(cs) => cs
    None => []
  }
}

///|
/// All rhyme groups a character can belong to under one system.
pub fn groups_of(
  lex : Lexicon,
  system : RhymeSystem,
  ch : Char,
) -> Array[String] {
  let out : Array[String] = []
  for r in lookup(lex, system, ch) {
    let mut seen = false
    for g in out {
      if g == r.group {
        seen = true
      }
    }
    if !seen {
      out.push(r.group)
    }
  }
  out
}

///|
/// Find a group that all characters can share. Returns the lexicographically
/// smallest witness so output is deterministic.
pub fn common_group(
  lex : Lexicon,
  system : RhymeSystem,
  chars : Array[Char],
  want_ping : Bool?,
) -> String? {
  if chars.length() == 0 {
    return None
  }
  let mut candidates = groups_of(lex, system, chars[0])
  let mut i = 1
  while i < chars.length() {
    let next : Array[String] = []
    for g in candidates {
      for r in lookup(lex, system, chars[i]) {
        if r.group == g {
          let ok = match want_ping {
            Some(ping) => is_ping(r.tone) == ping
            None => true
          }
          if ok {
            next.push(g)
            break
          }
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
  best
}

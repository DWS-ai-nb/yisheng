///|
/// Core value types shared by the Pingshui (诗) and Cilin (词) checkers.
///
/// A character is not assigned a single tone: classical Chinese has many
/// polyphonic characters (多音字), so a lexicon lookup returns every attested
/// reading and the checker accepts a position when *some* reading fits.
pub(all) enum Tone {
  Ping
  Ze
}

///|
pub fn is_ping(tone : Tone) -> Bool {
  match tone {
    Ping => true
    Ze => false
  }
}

///|
pub fn tone_label(tone : Tone) -> String {
  match tone {
    Ping => "平"
    Ze => "仄"
  }
}

///|
pub fn tone_code(tone : Tone) -> Char {
  match tone {
    Ping => 'p'
    Ze => 'z'
  }
}

///|
pub(all) enum RhymeSystem {
  Pingshui
  Cilin
}

///|
pub(all) enum Severity {
  Error
  Warning
  Info
}

///|
pub fn severity_label(level : Severity) -> String {
  match level {
    Error => "error"
    Warning => "warning"
    Info => "info"
  }
}

///|
/// One attested reading of a character.
pub struct Reading {
  tone : Tone
  /// Pingshui: "上平一东"; Cilin: "第四部".
  group : String
  /// "平" / "上" / "去" / "入". Used to keep 入声 rhymes apart in ci.
  tone_class : String
}

///|
pub struct Issue {
  code : String
  severity : Severity
  line : Int32
  /// 1-based character position inside the line; 0 means the whole line.
  col : Int32
  message : String
  expected : String
  actual : String
}

///|
pub struct LineView {
  text : String
  /// Expected pattern, one of 'p' / 'z' / 'a' per character.
  pattern : String
  /// Tone chosen for display, one of 'p' / 'z' / '?' per character.
  actual : String
  /// Columns (1-based) that carry an error, for inline marking.
  bad_cols : Array[Int32]
}

///|
pub struct Report {
  mut ok : Bool
  mut form : String
  mut lines : Array[LineView]
  mut issues : Array[Issue]
  notes : Array[String]
  mut rhyme : String
  /// Machine-readable identity of the matched template.
  mut template : String
}

///|
pub fn empty_report() -> Report {
  {
    ok: true,
    form: "",
    lines: [],
    issues: [],
    notes: [],
    rhyme: "",
    template: "",
  }
}

///|
/// One metrical format of a ci tune (词牌).
pub struct CiTune {
  name : String
  sketch : String
  author : String
  /// 'p' 平, 'z' 仄, 'a' 中 (either).
  pattern : String
  /// 0-based character offsets that must rhyme.
  rhymes : Array[Int32]
}

///|
/// Parsed lexicons and the curated ci catalogue.
pub struct Lexicon {
  pingshui : Map[Char, Array[Reading]]
  cilin : Map[Char, Array[Reading]]
  pingshui_groups : Map[String, Array[Char]]
  cilin_groups : Map[String, Array[Char]]
  pingshui_names : Array[String]
  cilin_names : Array[String]
  tunes : Array[CiTune]
}

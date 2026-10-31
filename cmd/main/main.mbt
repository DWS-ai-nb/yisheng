///|
/// yisheng command line: check / plan / rhyme / identify / list.
const VERSION : String = "0.2.1"

///|
fn usage() -> Unit {
  println("倚声 yisheng " + VERSION + " — 诗律词律引擎")
  println("")
  println("用法：")
  println(
    "  yisheng check <file> [--ci 词牌 | --form 五绝|七绝|五律|七律] [--json]",
  )
  println("  yisheng check --text \"诗句\" [--ci 词牌]")
  println("  yisheng plan <诗体> [--variant 0-3]")
  println("  yisheng plan --ci <词牌>")
  println(
    "  yisheng rhyme <韵部|字> [--system pingshui|cilin] [--tone 平|仄]",
  )
  println("  yisheng identify <file|--text>")
  println("  yisheng list [词牌名关键词]")
  println("  yisheng version")
  println("")
  println("示例：")
  println("  yisheng check examples/denggao.txt")
  println("  yisheng check examples/rumengling.txt --ci 如梦令 --json")
  println("  yisheng plan 七律 --variant 2")
  println("  yisheng rhyme 上平十灰 --tone 平")
}

///|
fn find_flag(argv : Array[String], name : String) -> String? {
  let mut i = 0
  while i + 1 < argv.length() {
    if argv[i] == name {
      return Some(argv[i + 1])
    }
    i = i + 1
  }
  None
}

///|
fn has_flag(argv : Array[String], name : String) -> Bool {
  for a in argv {
    if a == name {
      return true
    }
  }
  false
}

///|
fn is_command(a : String) -> Bool {
  a == "check" ||
  a == "plan" ||
  a == "rhyme" ||
  a == "identify" ||
  a == "list" ||
  a == "help" ||
  a == "version"
}

///|
fn positionals(argv : Array[String]) -> Array[String] {
  let out : Array[String] = []
  let mut i = 0
  // argv[0] is the executable; skip up to and including the subcommand.
  while i < argv.length() {
    if is_command(argv[i]) {
      i = i + 1
      break
    }
    i = i + 1
  }
  while i < argv.length() {
    let a = argv[i]
    if a == "--ci" ||
      a == "--form" ||
      a == "--text" ||
      a == "--tone" ||
      a == "--system" ||
      a == "--variant" ||
      a == "--file" {
      i = i + 2
      continue
    }
    if a == "--json" {
      i = i + 1
      continue
    }
    if a.length() > 0 && a.to_array()[0] != '-' {
      out.push(a)
    }
    i = i + 1
  }
  out
}

///|
fn read_path(path : String) -> Result[String, String] {
  let text = @fs.read_file_to_string(path) catch {
    _ => return Err("无法读取文件：" + path)
  }
  Ok(text)
}

///|
fn read_input(argv : Array[String]) -> Result[String, String] {
  match find_flag(argv, "--text") {
    Some(t) => Ok(t)
    None =>
      match find_flag(argv, "--file") {
        Some(path) => read_path(path)
        None => {
          let pos = positionals(argv)
          if pos.length() >= 1 {
            read_path(pos[0])
          } else {
            Err("缺少输入文件，或使用 --text 直接传入文本")
          }
        }
      }
  }
}

///|
fn tone_char(code : Char) -> Char {
  match code {
    'p' => '平'
    'z' => '仄'
    _ => '?'
  }
}

///|
fn render_view(view : @yisheng.LineView) -> String {
  let sb = StringBuilder()
  let chars = view.text.to_array()
  let actual = view.actual.to_array()
  for i in 0..<chars.length() {
    sb.write_char(chars[i])
    sb.write_char('[')
    sb.write_char(if i < actual.length() { tone_char(actual[i]) } else { '?' })
    sb.write_char(']')
    for c in view.bad_cols {
      if c == i + 1 {
        sb.write_string("×")
      }
    }
  }
  sb.to_string()
}

///|
fn render_pattern(view : @yisheng.LineView) -> String {
  let sb = StringBuilder()
  for c in view.pattern {
    sb.write_char(
      match c {
        'p' => '平'
        'z' => '仄'
        _ => '中'
      },
    )
  }
  sb.to_string()
}

///|
fn issue_line(issue : @yisheng.Issue) -> String {
  let loc = if issue.line == 0 {
    ""
  } else if issue.col == 0 {
    "第" + issue.line.to_string() + "句 "
  } else {
    "第" + issue.line.to_string() + "句第" + issue.col.to_string() + "字 "
  }
  "[" + issue.code + "] " + loc + issue.message
}

///|
fn render_human(report : @yisheng.Report) -> Unit {
  println(report.form + " · " + report.template)
  for note in report.notes {
    println("  " + note)
  }
  println("")
  for i in 0..<report.lines.length() {
    let view = report.lines[i]
    println("  " + (i + 1).to_string() + "  " + render_view(view))
    println("     " + render_pattern(view))
  }
  println("")
  let mut errors = 0
  let mut warnings = 0
  for issue in report.issues {
    match issue.severity {
      @yisheng.Error => errors = errors + 1
      @yisheng.Warning => warnings = warnings + 1
      _ => ()
    }
    println("  " + issue_line(issue))
  }
  println("")
  if report.ok {
    println(
      "结论：合律（错误 0，提示 " + warnings.to_string() + "）",
    )
  } else {
    println(
      "结论：不合律（错误 " +
      errors.to_string() +
      "，提示 " +
      warnings.to_string() +
      "）",
    )
  }
}

///|
fn json_escape(s : String) -> String {
  let sb = StringBuilder()
  for c in s {
    match c {
      '"' => sb.write_string("\\\"")
      '\\' => sb.write_string("\\\\")
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
fn json_string(s : String) -> String {
  "\"" + json_escape(s) + "\""
}

///|
fn render_json(report : @yisheng.Report) -> Unit {
  let sb = StringBuilder()
  sb.write_string("{")
  sb.write_string("\"ok\":" + (if report.ok { "true" } else { "false" }))
  sb.write_string(",\"form\":" + json_string(report.form))
  sb.write_string(",\"template\":" + json_string(report.template))
  sb.write_string(",\"rhyme\":" + json_string(report.rhyme))
  sb.write_string(",\"notes\":[")
  for i in 0..<report.notes.length() {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string(json_string(report.notes[i]))
  }
  sb.write_string("],\"issues\":[")
  for i in 0..<report.issues.length() {
    if i > 0 {
      sb.write_string(",")
    }
    let it = report.issues[i]
    sb.write_string("{")
    sb.write_string("\"code\":" + json_string(it.code))
    sb.write_string(
      ",\"severity\":" + json_string(@yisheng.severity_label(it.severity)),
    )
    sb.write_string(",\"line\":" + it.line.to_string())
    sb.write_string(",\"col\":" + it.col.to_string())
    sb.write_string(",\"message\":" + json_string(it.message))
    sb.write_string(",\"expected\":" + json_string(it.expected))
    sb.write_string(",\"actual\":" + json_string(it.actual))
    sb.write_string("}")
  }
  sb.write_string("],\"lines\":[")
  for i in 0..<report.lines.length() {
    if i > 0 {
      sb.write_string(",")
    }
    let v = report.lines[i]
    sb.write_string("{")
    sb.write_string("\"text\":" + json_string(v.text))
    sb.write_string(",\"pattern\":" + json_string(v.pattern))
    sb.write_string(",\"actual\":" + json_string(v.actual))
    sb.write_string("}")
  }
  sb.write_string("]}")
  println(sb.to_string())
}

///|
fn looks_like_shi(text : String) -> Bool {
  let lines = @yisheng.poem_lines(text)
  if lines.length() != 4 && lines.length() != 8 {
    return false
  }
  let w = lines[0].to_array().length()
  if w != 5 && w != 7 {
    return false
  }
  for l in lines {
    if l.to_array().length() != w {
      return false
    }
  }
  true
}

///|
fn parse_shi_form(name : String) -> @yisheng.ShiForm? {
  match name {
    "五绝" => Some(@yisheng.WuJue)
    "七绝" => Some(@yisheng.QiJue)
    "五律" => Some(@yisheng.WuLv)
    "七律" => Some(@yisheng.QiLv)
    _ => None
  }
}

///|
fn han_count(text : String) -> Int32 {
  let mut n = 0
  for line in @yisheng.poem_lines(text) {
    n = n + line.length()
  }
  n
}

///|
fn cmd_check(lex : @yisheng.Lexicon, argv : Array[String]) -> Unit {
  match read_input(argv) {
    Err(msg) => {
      println(msg)
      @sys.exit(2)
    }
    Ok(text) => {
      if han_count(text) == 0 {
        println(
          "输入中没有可判定的汉字，请检查文件内容或 --text 参数",
        )
        @sys.exit(2)
      }
      let report = match find_flag(argv, "--ci") {
        Some(name) => @yisheng.check_ci(lex, text, Some(name))
        None =>
          match find_flag(argv, "--form") {
            Some(form_name) =>
              match parse_shi_form(form_name) {
                Some(form) => @yisheng.check_shi(lex, text, Some(form))
                None => {
                  println("未知诗体：" + form_name)
                  @sys.exit(2)
                  @yisheng.empty_report()
                }
              }
            None =>
              if looks_like_shi(text) {
                @yisheng.check_shi(lex, text, None)
              } else {
                @yisheng.check_ci(lex, text, None)
              }
          }
      }
      if has_flag(argv, "--json") {
        render_json(report)
      } else {
        render_human(report)
      }
      if !report.ok {
        @sys.exit(1)
      }
    }
  }
}

///|
fn cmd_plan(lex : @yisheng.Lexicon, argv : Array[String]) -> Unit {
  match find_flag(argv, "--ci") {
    Some(name) => {
      let plans = @yisheng.plan_ci(lex, name)
      if plans.length() == 0 {
        println("内置词谱中没有该词牌：" + name)
        @sys.exit(2)
      }
      for p in plans {
        println(p.title)
        for line in p.lines {
          println("  " + line)
        }
        println("")
      }
    }
    None => {
      let pos = positionals(argv)
      if pos.length() < 1 {
        println("可用诗体：")
        for f in @yisheng.form_names() {
          println("  " + f)
        }
        return
      }
      match parse_shi_form(pos[0]) {
        None => {
          println("未知诗体：" + pos[0])
          @sys.exit(2)
        }
        Some(form) => {
          let variant = match find_flag(argv, "--variant") {
            Some(v) =>
              match @yisheng.parse_int_opt(v) {
                Some(n) =>
                  if n < 0 || n > 3 {
                    println("--variant 只接受 0-3，收到：" + v)
                    @sys.exit(2)
                    0
                  } else {
                    n
                  }
                None => {
                  println("--variant 需要 0-3 的整数，收到：" + v)
                  @sys.exit(2)
                  0
                }
              }
            None => 0
          }
          let plan = @yisheng.plan_shi(form, variant)
          println(plan.title)
          for line in plan.lines {
            println("  " + line)
          }
          println("")
          println(
            "说明：平/仄为定格，韵为韵脚；一三五不论见 README。",
          )
        }
      }
    }
  }
}

///|
fn find_groups(
  lex : @yisheng.Lexicon,
  system : @yisheng.RhymeSystem,
  needle : String,
) -> Array[String] {
  let out : Array[String] = []
  for g in @yisheng.group_names(lex, system) {
    if g == needle {
      return [g]
    }
  }
  for g in @yisheng.group_names(lex, system) {
    if g.contains(needle) {
      out.push(g)
    }
  }
  out
}

///|
fn cmd_rhyme(lex : @yisheng.Lexicon, argv : Array[String]) -> Unit {
  let pos = positionals(argv)
  if pos.length() < 1 {
    println(
      "用法：yisheng rhyme <韵部|字> [--system pingshui|cilin] [--tone 平|仄]",
    )
    @sys.exit(2)
  }
  let needle = pos[0]
  let system = match find_flag(argv, "--system") {
    Some("cilin") => @yisheng.Cilin
    Some("pingshui") => @yisheng.Pingshui
    Some(other) => {
      println("未知韵书：" + other)
      @sys.exit(2)
      @yisheng.Pingshui
    }
    None => @yisheng.Pingshui
  }
  let want_ping = match find_flag(argv, "--tone") {
    Some("平") => Some(true)
    Some("仄") => Some(false)
    Some(other) => {
      println("未知声调：" + other)
      @sys.exit(2)
      None
    }
    None => None
  }
  let groups = find_groups(lex, system, needle)
  if groups.length() > 0 {
    for g in groups {
      let chars = @yisheng.group_chars(lex, system, g)
      let filtered : Array[Char] = []
      for ch in chars {
        let mut keep = want_ping == None
        for r in @yisheng.lookup(lex, system, ch) {
          match want_ping {
            Some(p) =>
              if @yisheng.is_ping(r.tone) == p && r.group == g {
                keep = true
              }
            None => ()
          }
        }
        if keep {
          filtered.push(ch)
        }
      }
      println(g + "（" + filtered.length().to_string() + " 字）")
      let sb = StringBuilder()
      for i in 0..<filtered.length() {
        if i > 0 && i % 24 == 0 {
          println(sb.to_string())
          let _ = sb.reset()
        }
        sb.write_char(filtered[i])
      }
      if filtered.length() > 0 {
        println(sb.to_string())
      }
      println("")
    }
    return
  }
  let chars = needle.to_array()
  if chars.length() == 1 {
    let ch = chars[0]
    let readings = @yisheng.lookup(lex, system, ch)
    if readings.length() == 0 {
      println("「" + needle + "」不在所选韵书中。")
      @sys.exit(1)
    }
    println("「" + needle + "」的读音：")
    for r in readings {
      println(
        "  " +
        @yisheng.tone_label(r.tone) +
        " · " +
        r.group +
        " · " +
        r.tone_class +
        "声",
      )
    }
  } else {
    println("未找到韵部或单字：" + needle)
    @sys.exit(1)
  }
}

///|
fn cmd_identify(lex : @yisheng.Lexicon, argv : Array[String]) -> Unit {
  match read_input(argv) {
    Err(msg) => {
      println(msg)
      @sys.exit(2)
    }
    Ok(text) => {
      if han_count(text) == 0 {
        println(
          "输入中没有可判定的汉字，请检查文件内容或 --text 参数",
        )
        @sys.exit(2)
      }
      if looks_like_shi(text) {
        let r = @yisheng.check_shi(lex, text, None)
        println("接近诗体：" + r.form + " · " + r.template)
        println("问题数：" + r.issues.length().to_string())
        for i in r.issues {
          println("  " + issue_line(i))
        }
        println("")
      }
      let ranked = @yisheng.identify_ci(lex, text)
      println("词牌近似度（差异越小越接近）：")
      for item in ranked {
        let (name, score, sketch) = item
        println("  " + name + "  " + sketch + "  差异 " + score.to_string())
      }
    }
  }
}

///|
fn print_wrapped(items : Array[String], per_line : Int32) -> Unit {
  let sb = StringBuilder()
  let mut count = 0
  for i in 0..<items.length() {
    if count > 0 {
      sb.write_string("、")
    }
    sb.write_string(items[i])
    count = count + 1
    if count == per_line {
      println("  " + sb.to_string())
      let _ = sb.reset()
      count = 0
    }
  }
  if count > 0 {
    println("  " + sb.to_string())
  }
}

///|
fn cmd_list(lex : @yisheng.Lexicon, argv : Array[String]) -> Unit {
  let keyword = match find_flag(argv, "--ci") {
    Some(k) => k
    None => {
      let pos = positionals(argv)
      if pos.length() > 0 {
        pos[0]
      } else {
        ""
      }
    }
  }
  println("诗体：五绝、七绝、五律、七律")
  println("")
  let all_names = @yisheng.builtin_tune_names(lex)
  let names : Array[String] = []
  for n in all_names {
    if keyword == "" || n.contains(keyword) {
      names.push(n)
    }
  }
  if keyword == "" {
    println("内置词牌（" + all_names.length().to_string() + "）：")
  } else {
    println(
      "匹配「" +
      keyword +
      "」的词牌（" +
      names.length().to_string() +
      "/" +
      all_names.length().to_string() +
      "）：",
    )
  }
  print_wrapped(names, 8)
  println("")
  let groups = @yisheng.group_names(lex, @yisheng.Pingshui)
  println("平水韵部（" + groups.length().to_string() + "）：")
  print_wrapped(groups, 8)
}

///|
fn main {
  let argv = @env.args()
  let mut cmd = ""
  for a in argv {
    if a == "check" ||
      a == "plan" ||
      a == "rhyme" ||
      a == "identify" ||
      a == "list" ||
      a == "help" ||
      a == "version" {
      cmd = a
      break
    }
  }
  if has_flag(argv, "--version") || cmd == "version" {
    println("yisheng " + VERSION)
    return
  }
  if cmd == "help" || cmd == "" {
    usage()
    return
  }
  let lex = @yisheng.Lexicon::builtin()
  if cmd == "check" {
    cmd_check(lex, argv)
  } else if cmd == "plan" {
    cmd_plan(lex, argv)
  } else if cmd == "rhyme" {
    cmd_rhyme(lex, argv)
  } else if cmd == "identify" {
    cmd_identify(lex, argv)
  } else if cmd == "list" {
    cmd_list(lex, argv)
  }
}

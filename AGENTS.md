# AGENTS.md

Project-specific notes for maintainers and coding agents. Generic MoonBit
tooling advice is at <https://docs.moonbitlang.com>.

## Layout

- `rhyme.mbt` — parses the generated tables, builds `Lexicon`, exposes lookup.
- `shi.mbt` — 16 regulated-verse templates, template scoring, line analysis,
  rhyme intersection.
- `ci.mbt` — ci pattern matching, rhyme segments, identification.
- `plan.mbt` — `plan_shi` / `plan_ci` / group and tune listings.
- `text.mbt` — Han-character line splitting, prefix/split helpers.
- `cmd/main/` — CLI. Keep argument parsing and rendering here, not in the library.
- `data/` — auditable TSV tables and `manifest.json`.
- `data_generated.mbt` — generated constants; do not edit by hand.

## Commands

```bash
moon check
moon test
moon build --target wasm-gc
moon run cmd/main -- check examples/denggao.txt
python tools/prepare_data.py   # only when changing the data pipeline
```

## Rules that matter

- Keep `RhymeSystem` explicit in every lookup. Never silently fall back from
  Pingshui to Cilin (or the reverse).
- A character has a set of readings. Do not collapse it to one tone when adding
  checks; that is what makes 多音字 handling work.
- New error codes must be documented in `docs/DESIGN.md` and covered by a test.
- Do not add a data row without recording it in `manifest.json` (the generator
  handles this) and explaining the source.
- Keep the CLI output stable enough for scripts: `--json` must stay valid JSON,
  exit code 0 = 合律, 1 = 不合律, 2 = 用法/IO 错误.
- `moon fmt` before committing; `moon check` must stay warning-free.

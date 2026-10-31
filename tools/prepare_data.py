#!/usr/bin/env python3
"""Regenerate the compact Yisheng data tables from the upstream corpus.

Source: https://github.com/charlesix59/chinese_word_rhyme (MIT)
Pinned commit is recorded in data/manifest.json. The script downloads the
upstream JSON files into .cache/ (gitignored), validates them, and writes:

  data/pingshui.tsv   one line per Pingshui rhyme group
  data/cilin.tsv      one line per Cilin rhyme group and tone class
  data/citunes.tsv    curated ci-pattern table, one line per format
  data/generated/data.mbt  the same tables as MoonBit string constants

Only the compact tables are committed; the 19 MB upstream Ci_Tunes.json is not.
"""

from __future__ import annotations

import hashlib
import json
import pathlib
import subprocess
import urllib.request

REPO = "charlesix59/chinese_word_rhyme"
COMMIT = "ff0e9c13fb037c43e0eaa5dc929c0fe4fa2ffb18"
BASE = f"https://raw.githubusercontent.com/{REPO}/{COMMIT}/data"
FILES = ["Pingshui_Rhyme.json", "Cilin_Rhyme.json", "Ci_Tunes.json"]

CI_NAMES = [
    "忆江南", "如梦令", "相见欢", "生查子", "点绛唇", "浣溪沙", "菩萨蛮",
    "卜算子", "采桑子", "清平乐", "鹧鸪天", "虞美人", "南乡子", "临江仙",
    "蝶恋花", "渔家傲", "江城子", "定风波", "苏幕遮", "青玉案", "醉花阴",
    "声声慢", "念奴娇", "水调歌头", "满江红", "雨霖铃", "扬州慢",
]
MAX_FORMATS = 3

# The upstream Pingshui table omits 上声三讲 (its source page lost the group).
# These five common characters are restored from the standard Pingshui table
# and are tagged in the data file; everything else is untouched.
SANJIANG = "讲港棒蚌项"

# 词林正韵 data omits 沉 (only 沈 is listed under 第十三部 平声).
CILIN_SUPPLEMENT = [("第十三部", "平声", "沉")]

# Two very common characters missing from the upstream Pingshui extract.
PINGSHUI_SUPPLEMENT = [
    ("上平八齐", "啼"),
    ("下平十二侵", "沉"),
    # 下平一先's own name character is missing from the upstream list.
    ("下平一先", "先"),
]

ROOT = pathlib.Path(__file__).resolve().parent.parent
CACHE = ROOT / ".cache"
DATA = ROOT / "data"
GEN = ROOT


def fetch(name: str) -> bytes:
    CACHE.mkdir(exist_ok=True)
    path = CACHE / name
    if not path.exists():
        url = f"{BASE}/{name}"
        try:
            with urllib.request.urlopen(url, timeout=300) as r:
                path.write_bytes(r.read())
        except Exception:
            # Some networks reset urllib's TLS connection; curl is a fallback.
            subprocess.run(
                ["curl", "-sL", "--fail", "--max-time", "300", url, "-o", str(path)],
                check=True,
            )
    return path.read_bytes()


def sha256(b: bytes) -> str:
    return hashlib.sha256(b).hexdigest()[:16]


def dedupe(seq):
    seen = set()
    out = []
    for x in seq:
        if x not in seen:
            seen.add(x)
            out.append(x)
    return out


def pingshui() -> list[tuple[str, str]]:
    raw = json.loads(fetch("Pingshui_Rhyme.json"))
    prefix = {
        "上平声部": "上平",
        "下平声部": "下平",
        "上声部": "上声",
        "去声部": "去声",
        "入声部": "",
    }
    rows = []
    for tone, groups in raw.items():
        for group, chars in groups.items():
            name = prefix[tone] + group
            chars = dedupe(c for c in chars if c.strip())
            rows.append((name, "".join(chars)))
    # Insert 三讲 between 二肿 and 四纸 to keep the traditional order.
    insert_at = next((i for i, (g, _) in enumerate(rows) if g == "上声四纸"), len(rows))
    rows.insert(insert_at, ("上声三讲", SANJIANG))
    for group, chars in PINGSHUI_SUPPLEMENT:
        let_index = next((i for i, (g, _) in enumerate(rows) if g == group), None)
        if let_index is None:
            rows.append((group, chars))
        else:
            rows[let_index] = (group, rows[let_index][1] + chars)
    return rows


def cilin() -> list[tuple[str, str, str]]:
    raw = json.loads(fetch("Cilin_Rhyme.json"))
    rows = []
    for part, tones in raw.items():
        for tone, chars in tones.items():
            rows.append((part, tone, "".join(dedupe(c for c in chars if c.strip()))))
    for part, tone, chars in CILIN_SUPPLEMENT:
        idx = next((i for i, (p, t, _) in enumerate(rows) if p == part and t == tone), None)
        if idx is None:
            rows.append((part, tone, chars))
        else:
            rows[idx] = (part, tone, rows[idx][2] + chars)
    return rows


def citunes() -> list[tuple[str, str, str, str, str]]:
    raw = json.loads(fetch("Ci_Tunes.json"))
    rows = []
    for name in CI_NAMES:
        entry = raw.get(name)
        if not entry:
            raise SystemExit(f"missing ci tune: {name}")
        for fmt in entry["formats"][:MAX_FORMATS]:
            tones = []
            rhymes = []
            for i, slot in enumerate(fmt["tunes"]):
                tone = slot.get("tune", "中")
                tones.append({"平": "p", "仄": "z", "中": "a"}.get(tone, "a"))
                if slot.get("rhythm") in ("韵", "叠"):
                    rhymes.append(i)
            if not rhymes:
                continue
            sketch = fmt.get("sketch", "").strip()
            author = fmt.get("author", "").strip()
            rows.append((name, sketch, author, "".join(tones), ",".join(map(str, rhymes))))
    return rows


def mbt_string(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"').replace("\t", "\\t")


def emit_mbt(ping_rows, ci_rows, tune_rows):
    def block(name, rows):
        parts = [f'let {name} : String = "\\n" +']
        parts += [f'  "{mbt_string(line)}\\n" +' for line in rows]
        parts[-1] = parts[-1][:-2]  # drop trailing operator on the last line
        return "\n".join(parts) + "\n"

    ping = [f"{n}\t{c}" for n, c in ping_rows]
    ci = [f"{p}\t{t}\t{c}" for p, t, c in ci_rows]
    tune = [f"{n}\t{s}\t{a}\t{p}\t{r}" for n, s, a, p, r in tune_rows]

    src = [
        "// Generated by tools/prepare_data.py. Do not edit by hand.",
        f"// Source: {REPO} @ {COMMIT} (MIT); see data/README.md.",
        "",
        'let PINGSHUI_DATA : String = ""',
        'let CILIN_DATA : String = ""',
        'let CITUNES_DATA : String = ""',
        "",
    ]
    # Simpler: single leading newline and one concatenation chain per table.
    def chain(name, rows):
        body = " +\n  ".join(f'"{mbt_string(r)}\\n"' for r in rows)
        return f'const {name} : String =\n  "" +\n  {body}\n'

    src = [
        "// Generated by tools/prepare_data.py. Do not edit by hand.",
        f"// Source: {REPO} @ {COMMIT} (MIT); see data/README.md.",
        "",
        chain("PINGSHUI_DATA", ping),
        chain("CILIN_DATA", ci),
        chain("CITUNES_DATA", tune),
    ]
    (GEN / "data_generated.mbt").write_text("\n".join(src), encoding="utf-8")


def main():
    DATA.mkdir(exist_ok=True)
    GEN.mkdir(exist_ok=True)

    ping_rows = pingshui()
    ci_rows = cilin()
    tune_rows = citunes()

    (DATA / "pingshui.tsv").write_text(
        "".join(f"{n}\t{c}\n" for n, c in ping_rows), encoding="utf-8"
    )
    (DATA / "cilin.tsv").write_text(
        "".join(f"{p}\t{t}\t{c}\n" for p, t, c in ci_rows), encoding="utf-8"
    )
    (DATA / "citunes.tsv").write_text(
        "".join(f"{n}\t{s}\t{a}\t{p}\t{r}\n" for n, s, a, p, r in tune_rows),
        encoding="utf-8",
    )
    emit_mbt(ping_rows, ci_rows, tune_rows)

    manifest = {
        "source": f"https://github.com/{REPO}",
        "commit": COMMIT,
        "license": "MIT (data); Apache-2.0 (code)",
        "sha256_16": {
            name: sha256(fetch(name)) for name in FILES
        },
        "counts": {
            "pingshui_groups": len(ping_rows),
            "pingshui_chars": sum(len(c) for _, c in ping_rows),
            "cilin_rows": len(ci_rows),
            "cilin_chars": sum(len(c) for _, _, c in ci_rows),
            "ci_tunes": len(tune_rows),
            "ci_names": len({n for n, *_ in tune_rows}),
        },
        "supplement": {
            "pingshui:上声三讲": list(SANJIANG),
            "cilin:第十三部/平声": "沉",
            "pingshui:上平八齐/下平十二侵": "啼、沉",
            "reason": "absent from the upstream tables; restored from the standard rhyme books",
        },
        "ci_names": CI_NAMES,
    }
    (DATA / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(json.dumps(manifest["counts"], ensure_ascii=False))
    print("wrote", GEN / "data_generated.mbt")


if __name__ == "__main__":
    main()

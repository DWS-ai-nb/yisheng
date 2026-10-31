# 倚声 · yisheng

**中文诗律词律引擎。** 把平仄、押韵、粘对、孤平、三平调、词牌字数与韵脚，变成可运行、可测试、可嵌入的 MoonBit 库与命令行工具。

- CLI：`check`（逐字校验）· `plan`（生成平仄谱）· `rhyme`（查韵书）· `identify`（认词牌）· `list`（按关键词查词牌与韵部）
- 数据：平水韵 106 部 / 8,239 字；词林正韵 19 部；817 个词牌 / 1,275 种格式（每牌最多 2 体）
- 许可：代码 Apache-2.0；韵书数据 MIT（来源与补录见 [`data/README.md`](data/README.md)）

---

## 为什么需要它

写一首合律的七律，要同时满足：二四六分明、一三五不论、粘对、押平声韵、避孤平、避三平调；填一首《如梦令》，还要对 33 个字里每个字的平仄和 6 个韵脚。人眼校对容易漏，网页工具又无法嵌进编辑器、批改脚本或内容平台。

倚声把这件事拆成三层，全部离线、确定、可复现：

1. **读音层**：一个汉字不是“平”或“仄”，而是一组可能的读音（`Reading { tone, group }`）。多音字按“存在一个读音满足格律”判定，不误杀。
2. **格律层**：诗用 16 套近体诗模板（五/七言 × 绝/律 × 平起/仄起 × 首句入韵/不入韵）；词用逐字词谱和韵脚位置。
3. **报告层**：每条问题都带 `code / line / col / expected / actual`，既能给人看，也能直接喂给 CI 或审核系统。

## 快速开始

```bash
moon check
moon test          # 32 个测试，覆盖名篇、拗句、错韵、错字、词牌识别
moon run cmd/main -- check examples/denggao.txt
moon run cmd/main -- check examples/rumengling.txt --ci 如梦令
moon run cmd/main -- check examples/broken_tone.txt --json
moon run cmd/main -- plan 七律 --variant 2
moon run cmd/main -- rhyme 上平十灰 --tone 平
moon run cmd/main -- list 花        # 按关键词查词牌，现收 817 个
```

输出示例（《登高》，节选）：

```
七律 · 仄起首句入韵
  押韵：上平十灰（平水韵）

  1  风[平]急[仄]天[平]高[平]猿[平]啸[仄]哀[平]
     仄仄平平仄仄平
  ...
结论：合律（错误 0，提示 0）
```

## 三个使用场景

1. **语文教学 / 作业批改**：学生交来一首七绝，`check` 逐字标出“第 1 句第 4 字应为仄、实为平”和“第 4 句韵脚不入韵”，教师不必手工对谱。
2. **诗词平台 / 期刊投稿审核**：后端调用 `check_shi` / `check_ci`，拿结构化 `Report` 做自动分流；`--json` 可直接落库或进 CI。
3. **创作辅助**：`plan 七律 --variant 2` 给出平仄谱和韵脚位置，`rhyme 上平十灰` 列出可用韵字，`identify` 帮你判断一首草稿最接近哪个词牌。

完整输入、输出与验证方式见 [`docs/SCENARIOS.md`](docs/SCENARIOS.md)。

## 库 API

```mbt
let lex = @yisheng.Lexicon::builtin()

// 诗：自动识别五/七言、绝/律，并选出最接近的起式
let report = @yisheng.check_shi(lex, poem_text, None)

// 词：指定词牌；长度不符会报 CI_LENGTH，韵脚按同段同部校验
let report = @yisheng.check_ci(lex, ci_text, Some("如梦令"))

// 创作辅助
let plan = @yisheng.plan_shi(@yisheng.QiLv, 2)
let chars = @yisheng.group_chars(lex, @yisheng.Pingshui, "上平十灰")
```

`Report` 包含 `ok`、`form`、`template`、`rhyme`、逐句 `LineView`（原文 / 定格 / 实际平仄 / 错位）和 `Issue[]`。

## 设计要点

- **多音字不是噪声，是约束。** `看` 有平、去两读；韵脚取所有韵脚字读音集合的交集，非韵脚按“任一读音符合定格”判定。这样既不会把 `看` 误判，也不会把“作者实际读错”当成硬错误——报告只声称“存在合律读法”。
- **一三五不论，二四六分明。** 五言固定第 2/4/5 字，七言固定第 2/4/6/7 字；第 1/3/5 字只在触发孤平、三平调、三仄尾时提示。
- **词韵允许同部通押。** 词林正韵把平水韵的“灰”韵拆进第三/第五部，晏殊《浣溪沙》“杯台回来徊”因此跨部。引擎先按词林正韵部求交，失败再按平水韵同部求交，并在 `notes` 中说明。
- **换韵按声调切段。** 《菩萨蛮》《虞美人》这类平仄交替押韵的词牌，按韵脚预期声调的变化切段，段内要求同部；同声调换韵的词牌不在当前保证范围内。

细节与边界见 [`docs/DESIGN.md`](docs/DESIGN.md)。

## 数据与来源

| 数据 | 说明 |
| --- | --- |
| 平水韵 | 106 部、10,386 条字-韵记录、8,239 个汉字 |
| 词林正韵 | 19 部、33 个声调分组、5,037 个汉字 |
| 词谱 | 817 个词牌、1,275 种格式（每牌最多 2 体，含例词作者与字数/韵脚说明） |

来源：[`charlesix59/chinese_word_rhyme`](https://github.com/charlesix59/chinese_word_rhyme)（MIT），固定提交 `ff0e9c1`。上游表缺“上声三讲”等少量字，补录项逐条记录在 [`data/manifest.json`](data/manifest.json) 与 [`data/README.md`](data/README.md)。`tools/prepare_data.py` 可重新生成全部表。

## 测试

```bash
moon test
```

32 个测试，包括：

- 15 首名篇必须通过：杜甫《登高》《春望》《蜀相》、李白《早发白帝城》《独坐敬亭山》、王之涣《登鹳雀楼》、杜牧《山行》、李商隐《无题》、王维《山居秋暝》，以及李清照《如梦令》、白居易《忆江南》、晏殊《浣溪沙》、李煜《虞美人》、晏殊《蝶恋花》、苏轼《水调歌头》。
- 错平仄、错韵、错字数、孤平、三平调必须被检出，且行列号正确。
- 多音字、未知字、词牌识别、平仄谱、韵书查询的行为被固定。

## 边界（请不要把它当成“诗词裁判”）

- 不判断意境、对仗、典故、重复字，也不判断作者实际想读哪个音；只判断“是否存在合律读法”。
- 对句相救未单独建模：严格位上的拗救可能被报为平仄不合；我们测试的名篇不依赖该规则。
- 词谱覆盖 817 个词牌、1,275 种格式（每牌最多 2 体）；同声调换韵、叠韵、领字等特殊体式未完整覆盖。
- 韵表未收的字按“未知”提示并跳过判定，不臆造读音。
- 平水韵/词林正韵本身存在异读与流派差异；本项目的判定以所附数据为准。

## 与相近项目的区别

已核对 Mooncakes 与 GitHub 上的相近项目，差异说明见 [`docs/RELATED.md`](docs/RELATED.md)。简言之：`moonlayout` 做的是段落断行与分词，`mbt-typeset` 做的是中英文间距/标点校对，`moonbitlang/typst` 是排版引擎移植；它们都不提供平水韵/词林正韵数据、近体诗定格判定或词牌逐字校验。倚声不与它们共享代码或数据管道。

## 开发

```bash
python tools/prepare_data.py   # 重新生成韵书与词谱（需要网络；结果已提交）
moon check
moon test
moon run cmd/main -- help
```

目录：`rhyme.mbt`（韵书与查询）、`shi.mbt`（近体诗）、`ci.mbt`（词）、`plan.mbt`（平仄谱）、`cmd/main/`（CLI）、`data/`（可审计的 TSV 与清单）、`tools/`（数据生成）。

## License

代码 [Apache-2.0](LICENSE)；韵书与词谱数据 MIT，署名见 [NOTICE](NOTICE)。古诗词原文均为公有领域。

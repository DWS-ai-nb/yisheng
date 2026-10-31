# 相近项目与差异核对

核对日期：2026-10-31。方法：在 Mooncakes 用 `unicode / linebreak / typography / pinyin / citation / poetry / prosody / srt / font` 等关键词检索，并在 GitHub 检索 `unicode language:MoonBit`、`moonbit text layout`、`pingshuiyun`、`chinese poetry rhyme`。这是一次面向选题的定向核对，不是穷尽性调查；未列出的项目不代表不存在。

## MoonBit 生态

| 项目 | 它做什么 | 与本项目的区别 |
| --- | --- | --- |
| [`ShiChengxu/moonlayout`](https://mooncakes.io/docs/ShiChengxu/moonlayout) | Unicode 17 段落排版、断行、词/句切分 | 排版层：决定一行在哪里断。没有平水韵/词林正韵数据，没有近体诗定格、粘对、孤平、词牌逐字校验。倚声不做断行。 |
| [`Mr-Houjie/mbt-typeset`](https://mooncakes.io/docs/Mr-Houjie/mbt-typeset) | 中文排版校对：中英文间距、全角标点、术语统一，含 CLI | 正字/排版层：修文本的写法。倚声判断的是字的声调与韵部，不修改原文。 |
| [`moonbitlang/typst`](https://mooncakes.io/docs/moonbitlang/typst) | Typst 排版引擎的 MoonBit 移植 | 通用排版引擎；不提供中国古典诗律/词律判定。 |
| [`moonbitlang/pagelayout`](https://mooncakes.io/docs/moonbitlang/pagelayout) | 分页文档布局 IR 与 SVG/PDF 后端 | 文档分页；与韵书、格律无关。 |
| [`wbgxiaosu/moonqipai`](https://mooncakes.io/docs/wbgxiaosu/moonqipai) | 棋类/牌类规则基础（Go、象棋、五子棋等） | 游戏规则；不含诗词格律。 |

结论：在本次检索范围内，没有发现 MoonBit 项目提供“韵书数据 + 近体诗定格 + 词牌逐字校验”的组合。这个结论只针对检索到的项目。

## MoonBit 之外

| 项目/产品 | 关系 | 说明 |
| --- | --- | --- |
| [`charlesix59/chinese_word_rhyme`](https://github.com/charlesix59/chinese_word_rhyme) | **数据来源**（MIT） | 提供平水韵、词林正韵、词谱 JSON。倚声用 `tools/prepare_data.py` 转成紧凑 TSV，并记录了缺失字补录与固定提交号。代码未复用。 |
| 搜韵、诗词吾爱等网页工具 | 同类需求 | 提供格律检测，但为闭源网页服务，无法作为 MoonBit 库嵌入编辑器、批改脚本或内容平台；本项目未使用其代码或数据。未逐一核对其实现细节。 |
| `jkak/pingShuiYun` 等 Python 工具 | 同类数据工具 | 仓库未声明许可证，本项目未使用其代码或数据，仅作为“该领域存在既有工具”的旁证。 |
| 王力《诗词格律》等通行格律理论 | 规则依据 | 近体诗定格、孤平、三平调、粘对等规则属于公有领域的通行知识；本项目用自己的模板与代码实现。 |

## 与用户既有项目的关系

倚声与 WasmSlim、MoonGate、TideWeave、Kiln、WageKit、TableGuard、MoonGeo、AgentCanary 等既有项目没有代码、数据或运行时依赖关系；不复用其引擎、模型或输出格式。若申报材料需要披露，应按实际情况说明“独立新建仓库、独立实现”。

## 仍未查证

- 是否存在未发布到 Mooncakes、也未在 GitHub 以 `MoonBit` 标注的中文格律库。
- 商业词谱/韵书数据库的覆盖范围与授权条款（本项目不使用商业数据）。
- 各网页工具的具体判定口径（是否处理多音字、是否支持拗救）。

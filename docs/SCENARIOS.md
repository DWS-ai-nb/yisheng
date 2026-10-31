# 三个使用场景

以下命令都在仓库根目录执行，输出来自本次实际运行（Windows + MoonBit `0.1.20261021`）。所有示例文本均为公有领域作品或为演示而构造。

## 场景一：语文教师批改学生习作

**使用者**：中学语文教师、诗词社团指导老师。
**问题**：学生交来一首七绝，教师需要逐字对平仄谱，还要判断韵脚是否同部；手工做既慢又容易漏。
**输入**：`examples/student_qijue.txt`

```
朝辞白云彩云间，千里江陵一日还。
两岸猿声啼不住，轻舟已过万重天。
```

**操作**：

```bash
moon run cmd/main -- check examples/student_qijue.txt
```

**预期输出**（节选）：

```
  1  朝[平]辞[平]白[仄]云[平]×彩[仄]云[平]间[平]
     平平仄仄仄平平
  ...
  [SHI_TONE] 第1句第4字 第4字应为仄，实为平
  [RHYME_MISMATCH] 第4句第7字 韵脚「天」与首句「间」不押同一韵部

结论：不合律（错误 2，提示 0）
```

**验证方式**：命令退出码为 `1`；`SHI_TONE` 的 `line=1, col=4, expected=仄, actual=平`；`RHYME_MISMATCH` 指向第 4 句第 7 字。对应自动化测试 `shi_test.mbt` 中的 “wrong tone is reported at the fixed position” 与 “wrong rhyme is reported”。

**教师得到什么**：不用自己数第几个字，报告直接给出“第几句第几字、应为平还是仄”；韵脚问题指出具体两个字，便于讲解。

## 场景二：诗词平台/期刊的投稿初筛

**使用者**：诗词公众号编辑、期刊初审、内容平台审核脚本。
**问题**：每天收到大量投稿，需要先过滤明显不合律的稿件，再人工看合律的；审核系统需要结构化结果，而不是一段中文。
**输入**：`examples/rumengling.txt`（李清照《如梦令》）

**操作**：

```bash
moon run cmd/main -- check examples/rumengling.txt --ci 如梦令 --json
```

**预期输出**（节选，实际为一行 JSON）：

```json
{"ok":true,"form":"如梦令（单调三十三字，七句五仄韵、一叠韵）","template":"如梦令·后唐庄宗",
 "rhyme":"","notes":["用韵：第四部（仄）"],"issues":[],
 "lines":[{"text":"常记溪亭日暮","pattern":"azapaz","actual":"pzppzz"}, ...]}
```

**验证方式**：命令退出码为 `0`；`ok=true`；`issues` 为空；`notes` 含“第四部（仄）”。自动化测试 “如梦令 李清照 passes” 固定了这一行为。对不合律稿件，退出码为 `1`，`issues[]` 里每条都有 `code/line/col/expected/actual`。

**批量用法**（示例）：

```bash
for f in submissions/*.txt; do
  moon run cmd/main -- check "$f" --json || echo "REJECT $f"
done
```

**编辑得到什么**：一个可直接落库的 `Report`，不需要解析自然语言；`ok`、`rhyme`、`issues` 三个字段就能完成分流。

## 场景三：创作者的平仄谱与韵字查询

**使用者**：诗词创作者、诗词 App 的“按谱填词”功能开发者。
**问题**：想写一首七律，但记不住某一式的平仄；想押“灰”韵，但手边没有韵书；写完后不确定最接近哪个词牌。
**操作**：

```bash
moon run cmd/main -- plan 七律 --variant 2
moon run cmd/main -- rhyme 上平十灰 --tone 平
moon run cmd/main -- identify examples/rumengling.txt
```

**预期输出**（节选）：

```
七律·仄起首句入韵
  仄仄平平仄仄平（韵）
  平平仄仄仄平平（韵）
  ...

上平十灰（… 字）
灰恢魁隈回徊槐枚梅媒煤瑰雷垒催摧堆陪杯醅嵬推开哀埃台苔该才材财裁来莱栽哉灾猜胎孩…

词牌近似度（差异越小越接近）：
  如梦令  单调三十三字，七句五仄韵、一叠韵  差异 0
  江城子  单调三十五字，七句五平韵  差异 1002
  ...
```

**验证方式**：`plan` 输出 8 行、每行 7 个平/仄字，韵脚带“（韵）”；`rhyme` 列出的字都能在 `data/pingshui.tsv` 的“上平十灰”行找到；`identify` 的第一名与输入词牌一致（自动化测试 “identify ci picks 如梦令”）。

**创作者得到什么**：从“查谱—选韵—自查”三步都在终端完成，不需要打开浏览器；`plan` 也可以被 App 直接调用生成填词界面。

## 复现全部验证

```bash
moon test
# Total tests: 30, passed: 30, failed: 0
```

测试覆盖 15 首名篇、4 类错误、孤平/三平调、多音字、未知字、词牌识别、平仄谱与韵书查询。若数据表被改动，`moon test` 会立刻暴露回归。

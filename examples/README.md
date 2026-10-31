# 示例

| 文件 | 内容 | 命令 | 预期 |
| --- | --- | --- | --- |
| `denggao.txt` | 杜甫《登高》，七律 | `moon run cmd/main -- check examples/denggao.txt` | 合律，押上平十灰 |
| `chunwang.txt` | 杜甫《春望》，五律 | `moon run cmd/main -- check examples/chunwang.txt` | 合律 |
| `zaofa.txt` | 李白《早发白帝城》，七绝 | `moon run cmd/main -- check examples/zaofa.txt` | 合律，押上平十五删 |
| `rumengling.txt` | 李清照《如梦令》 | `moon run cmd/main -- check examples/rumengling.txt --ci 如梦令` | 合律，第四部仄韵 |
| `student_qijue.txt` | 演示用习作：一处平仄、一处韵脚错误 | `moon run cmd/main -- check examples/student_qijue.txt` | 2 个错误，退出码 1 |
| `broken_tone.txt` | 只改一个固定位 | `moon run cmd/main -- check examples/broken_tone.txt` | `SHI_TONE` |
| `broken_rhyme.txt` | 只换一个韵脚 | `moon run cmd/main -- check examples/broken_rhyme.txt` | `RHYME_MISMATCH` |

`student_qijue.txt`、`broken_*.txt` 是在《早发白帝城》基础上为演示构造的，不是原作。

批量检查：

```bash
for f in examples/*.txt; do
  moon run cmd/main -- check "$f" --json >/dev/null 2>&1
  echo "$? $f"
done
```

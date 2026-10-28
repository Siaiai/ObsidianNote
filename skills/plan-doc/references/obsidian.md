# 可选：Obsidian 笔记属性

本 skill 默认用通用 frontmatter：`title / status / created / updated`。
如果文档在 Obsidian vault 内，笔记属性参考该 vault 的 `规范.md` 或模板，不要在本 skill 里另立一套。

## 常用映射

| 通用字段 | Obsidian 字段 | 说明 |
|---|---|---|
| `title` | `任务` / `项目` | 任务笔记用 `任务: "[[YYMMDD任务]]"`；项目笔记用 `项目:` |
| `status` | `状态` | 待办 / 进行 / 完成（或项目 / 学习的对应状态） |
| `created` | `创建时间` | `YYYY-MM-DDTHH:mm:ss` |
| `updated` | 正文 `最后更新` | 顶部引用块 |
| `completed` | `完成时间` | `状态=完成` 时必填 |

## 规则

- 以 vault 的 `规范.md` 为准；wiki 内链、数组格式、时间带秒都按它
- 通用字段可以保留，也可以删掉；不要两套状态互相矛盾
- 文件位置也按 vault 规范，例如 `{领域}/{项目}/YYMMDD{任务}.md`
- 不在 vault 内时不要引入这些属性
- 如果 vault 里已有规划模板，优先参考它；没有就用本 skill 的 `assets/plan-template.md` 再按 vault 属性补齐

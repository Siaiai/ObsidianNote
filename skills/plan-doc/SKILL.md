---
name: plan-doc
description: >
  Maintain long-lived project planning documents (plan / task table / implementation log /
  change log) in any repository or folder. Use when the user creates or updates PLAN.md,
  docs/plan.md, *.plan.md, asks 下一步做什么 / 这条做完了 / 需求变了 / 检查规划, or invokes
  /plan-new, /plan-next, /plan-done, /plan-change, /plan-check. Plain Markdown with no
  Obsidian dependency. Covers task IDs, P0/P1 ordering, change log (C IDs), one-line
  implementation records, archiving, and lint. Do NOT use for one-off edits or pure Q&A.
---

# plan-doc — 长期规划文档工作流

用于「一个项目跨多天、多任务、需求会变」的规划文档。纯 Markdown，不依赖 Obsidian 或任何笔记软件；放在哪个仓库、哪个目录都可以。

> 首次使用、想知道怎么组织规划AI / 执行AI 的完整流程，先读 `references/sop.md`（含可复制提示词）。

## 何时用

- 新建或维护项目规划：`PLAN.md`、`docs/plan.md`、`*.plan.md`，或用户指定的任意路径
- 从规划文档领任务、写实施记录、收尾归档
- 需求变更，任务取消 / 取代 / 延期
- 用户说：下一步做什么、这条做完了、需求变了、检查规划
- 调用 `/plan-*` 命令

不适用：一次性小改动、纯问答、写文章。

## 文件位置

- 默认：项目根 `PLAN.md`；也可用 `docs/plan.md` 或用户指定路径
- 命令优先用显式路径；未指定时按 `PLAN.md` → `docs/plan.md` → 最近修改的 `*.plan.md` 查找
- 如果目标文件位于 Obsidian vault 内：位置按该 vault 规范（如 `{领域}/{项目}/YYMMDD{任务}.md`），笔记属性参考 vault 的 `规范.md` / 模板（映射见 `references/obsidian.md`）；否则使用本 skill 的通用格式
- 本 skill 不要求任何特定属性名；通用格式只有 `title / status / created / updated`

## 单一事实源（冲突优先级）

1. 目标仓库的 `AGENTS.md` / `README.md`
2. 本 skill 的 `references/format.md`
3. 目标文档 §2 契约
4. 代码与测试

在 Obsidian vault 内：vault 的 `规范.md` 优先于本 skill 的 frontmatter 约定。

代码/测试与文档冲突时：**以代码为准**，并把差异作为一条 C 变更写回文档。

## 铁律

1. 任务 ID 只增不改，取消的号永久作废；新任务往后排。
2. 已完成任务的原文不改；后续一切变化只追加 C 条目。
3. `[x]` 只代表验证命令已跑过并通过；没跑不许勾。
4. §1 只放未完成；完成 / 取消 / 取代 / 延期移到 §6 归档。
5. 一条任务 = 一次会话能完成 + 验证命令可复制。
6. 需求变更必须打到四个面：任务、契约、测试、文档。
7. 每次会话结束更新三处：§0 状态、§1 下一条、§5 一行记录。
8. 一功能一机制：优先扩展现有机制；新建机制必须先立 D 决策，执行中发现要新建必须停下。
9. 不删改无关文件；不碰 `.git/`；不 commit / push，除非用户明确要求。

## 命令

| 命令 | 作用 |
|---|---|
| `/plan-new <路径> <标题>` | 新建规划文档骨架 |
| `/plan-next <文档或任务ID>` | 只读，输出下一条任务的执行提示词 |
| `/plan-done <文档> <任务ID>` | 跑验证，通过才勾选并更新三处 |
| `/plan-change <文档> <描述>` | 记录 C 变更并更新受影响任务 |
| `/plan-check <文档或目录>` | 跑 lint，汇总 ERROR / WARN |

命令未加载时，按 `references/tasks.md` 中的同名流程手工执行。

## Lint 门禁

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill目录>\scripts\plan_lint.ps1" -Path "<文档>" -Strict
```

- ERROR：必须修完才能继续
- WARN：可以接受，但回复里要逐条说明原因
- `/plan-done`、`/plan-change`、`/plan-check` 收尾必须跑一次
- 文档含 `<!-- plan-doc:v1 -->` 标记才启用严格检查；旧文档自动降级为兼容模式（只报 WARN）
- 目录扫描加 `-PlanOnly` 只检查含该标记的规划文档；显式传文件总是检查

## 参考文件

- `references/sop.md`：完整执行教程 + 提示词（规划AI / 执行AI，从建规划到收尾）
- `assets/plan-template.md`：`/plan-new` 使用的创建模板（通用 Markdown，含规范注释）
- `references/format.md`：完整骨架、各节写什么、变更 / 归档 / 血缘
- `references/tasks.md`：任务粒度、ID、验收、拆分、变更操作流
- `references/pitfalls.md`：常见坑
- `references/obsidian.md`：可选的 Obsidian 笔记属性映射（不绑定）

## 安装与加载

- 放在 `~/.config/opencode/skills/plan-doc/`，或用 `skills.paths` 指向本目录
- 新增或修改 skill / command 后需要重启 opencode 才生效

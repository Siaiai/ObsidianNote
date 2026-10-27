---
name: plan-doc
description: >
  维护长期项目规划文档（规划文档/任务表/实施记录/需求变更）时使用。
  Use when the user creates or updates a long-lived plan under
  工作/{项目}/YYMMDD*.md, asks 下一步做什么 / 这条做完了 / 需求变了 / 检查规划,
  or invokes /plan-new, /plan-next, /plan-done, /plan-change, /plan-check.
  Covers task IDs, P0/P1 ordering, change log (C IDs), one-line implementation
  records, archiving, and lint. Do NOT use for one-off edits or pure Q&A.
---

# plan-doc — 长期规划文档工作流

用于「一个项目跨多天、多任务、需求会变」的规划文档。核心是：任务可增量追加、变更可追溯、实施记录只有一行、每次会话都能无缝交接。

## 何时用

- 新建或维护 `工作/{项目}/YYMMDD{任务}.md` 形式的规划文档
- 从规划文档领任务、写实施记录、收尾归档
- 需求变更，任务取消 / 取代 / 延期
- 用户说：下一步做什么、这条做完了、需求变了、检查规划
- 调用 `/plan-*` 命令

不适用：一次性小改动、纯问答、写文章。

## 单一事实源（冲突优先级）

1. vault 根目录 `规范.md`：frontmatter、目录、命名、属性
2. 本 skill：文档结构、任务 / 变更 / 归档规则
3. 目标文档 §2 契约
4. 代码与测试

代码/测试与文档冲突时：**以代码为准**，并把差异作为一条 C 变更写回文档。

## 文档位置

- 默认 vault：`C:\Users\SiaZh\OneDrive\SIA的obsidian系统`（不存在时询问用户）
- 规划文档：`工作/{项目}/YYMMDD{任务}.md`
- 结构模板：`资源/模板/规划文档.md`
- 创建表单：`资源/form-flow插件/form/工作规划.cform`

## 铁律

1. 任务 ID 只增不改，取消的号永久作废；新任务往后排。
2. 已完成任务的原文不改；后续一切变化只追加 C 条目。
3. `[x]` 只代表验证命令已跑过并通过；没跑不许勾。
4. §1 只放未完成；完成 / 取消 / 取代 / 延期移到 §6 归档。
5. 一条任务 = 一次会话能完成 + 验证命令可复制。
6. 需求变更必须打到四个面：任务、契约、测试、文档。
7. 每次会话结束更新三处：§0 状态、§1 下一条、§5 一行记录。
8. vault 红线：不删改无关文件；不碰 `.obsidian/`、`.git/`、`资源/` 下的插件配置。

## 命令

| 命令 | 作用 |
|---|---|
| `/plan-new <项目> <名称>` | 新建规划文档骨架 |
| `/plan-next <文档或任务ID>` | 只读，输出下一条任务的执行提示词 |
| `/plan-done <文档> <任务ID>` | 跑验证，通过才勾选并更新三处 |
| `/plan-change <文档> <描述>` | 记录 C 变更并更新受影响任务 |
| `/plan-check <文档>` | 跑 lint，汇总 ERROR / WARN |

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

- `references/format.md`：完整骨架、各节写什么、变更 / 归档 / 血缘
- `references/tasks.md`：任务粒度、ID、验收、拆分、变更操作流
- `references/pitfalls.md`：20 条常见坑

## 安装与加载

- 本 skill 放在 vault 的 `skills/plan-doc/`，通过 opencode 全局配置 `skills.paths` 注册
- 新增或修改 skill / command 后需要重启 opencode 才生效
- 换机器时：确认 `~/.config/opencode/opencode.json` 的 `skills.paths` 指向 vault 的 `skills` 目录

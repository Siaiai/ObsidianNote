---
name: kb-workflow
description: >
  维护绑定到 Obsidian 知识库的项目文档、任务笔记、设计文档与 ADR。
  Use when the user creates, updates, or syncs project docs, task notes,
  design docs, or ADRs into their Obsidian vault, or asks to bind/initialize
  a project's knowledge base. Treats the vault's 规范.md as the single
  source of truth. Do NOT use for unrelated file edits, or when no Obsidian
  knowledge base is involved.
---

# kb-workflow — 知识库维护工作流

把开发工程（QT / 嵌入式 / 软件等）与 Obsidian 知识库绑定后，项目文档、任务笔记、设计决策统一维护在知识库内，工程内只留一行指向知识库的指针。本 skill 定义这套维护流程。

## 定位知识库（不硬编码路径）

本 skill 不假设 vault 在某个固定位置。需要定位时按优先级：

1. 工程 `AGENTS.md` 或当前会话已记录的 vault 路径 → 直接用
2. 否则**询问用户**：「请告诉我 Obsidian 知识库的根目录绝对路径」，用用户给的路径
3. 得到路径后写入工程 `AGENTS.md`，下次免问

## 单一事实源

任何读写知识库前，**第一步完整 Read vault 根目录的 `规范.md`**，严格按其规则执行（目录结构、frontmatter 格式、wiki 内链规则、各笔记模板）。规范正文只存在于 `规范.md`，本 skill 不复制，避免漂移。

## 核心操作流程

**新建任务笔记**
1. 确认 `{领域}/项目/{项目名}.md` 存在，不在则先建项目文件
2. 严格按 `规范.md` 中对应领域任务模板生成 frontmatter（`任务`、`相关任务` 留空、`截止时间` 带秒）
3. 文件放 `{领域}/{项目名}/YYMMDD{任务}.md`，内容为待办列表

**完成任务**
1. 勾选待办项 `- [x]`
2. `状态` 改为「完成」
3. 填写 `完成时间`（带秒）

**产出设计文档 / 文章**
1. frontmatter `项目: "[[项目名]]"` 保证正确
2. 项目文件的 dataview 查询自动汇总，**无需手动改项目文件**

## init 模式（绑定 / 初始化知识库）

触发词：「初始化知识库」「绑定这个项目到知识库」，或首次在工程里要求维护知识库时执行：

1. 询问 vault 路径（见上）
2. 探测当前 AI 工具类型，生成该工具认的固定段
3. 幂等写入（已存在则跳过）
4. 需要授权时提示用户放行 vault 目录

各工具固定段写法与配置文件路径见 `references/init-guide.md`。

## ⚠️ Gotchas

- **不要修改/删除知识库任何文件，除非用户明确要求** — 最高红线
- 普通任务笔记的 `项目` 用 `[[wikilink]]`，只有项目文件自身用纯文本
- `相关任务` / `相关项目` 无关联时留空行，**不要写 `- ""`**
- 时间必须带秒：`YYYY-MM-DDTHH:mm:ss`
- 不要复制规范正文到 SKILL 或工程文件，只引用 vault 的 `规范.md`
- 不要假设 vault 路径，未确认时先问用户

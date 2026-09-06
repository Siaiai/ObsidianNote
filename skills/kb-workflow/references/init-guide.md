# init 固定段写法指南

init 模式按当前 AI 工具自动生成对应的固定段。各工具的**固定段正文统一**（只做指针，不复制规范），差异只在放哪、加载格式。写入前先检查是否已存在（幂等）。

## 统一固定段正文

```markdown
## 知识库
本项目文档 / 任务 / 决策统一维护在 Obsidian 知识库：`<vault 路径>`
涉及项目文档、任务笔记、设计文档、ADR，或查阅知识库时，加载 skill `kb-workflow` 执行。
```

`<vault 路径>` 替换为用户提供的 vault 根目录绝对路径（如 `C:\Users\SiaZh\OneDrive\SIA的obsidian系统`）。

## 各工具落点

| 工具 | 全局位置 | 工程位置 | 格式要点 |
|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | 工程根 `CLAUDE.md` 或 `AGENTS.md` | 无 frontmatter，直接追加段落 |
| opencode / Codex | `~/.config/opencode/AGENTS.md` | 工程根 `AGENTS.md` | 无 frontmatter |
| Cursor | `~/.cursor/rules/*.mdc` | `.cursor/rules/knowledge.mdc` | 需要 frontmatter：`---\ndescription: 知识库维护\n---` |
| GitHub Copilot | — | 工程根 `AGENTS.md` | 同 opencode |

## 授权放行（opencode）

opencode 访问 vault 需要在 `~/.config/opencode/opencode.json`（或工程 config）中放行外部目录：

```jsonc
{
  "permission": {
    "external_directory": {
      "<vault 路径，反斜杠改斜杠>/**": "allow"
    }
  },
  "references": {
    "obsidian": {
      "path": "<vault 路径>",
      "description": "个人知识库：项目文档、任务笔记、设计文档、ADR"
    }
  }
}
```

例如 vault 为 `C:\Users\SiaZh\OneDrive\SIA的obsidian系统` 时：

```jsonc
{
  "permission": {
    "external_directory": {
      "C:/Users/SiaZh/OneDrive/SIA的obsidian系统/**": "allow"
    }
  },
  "references": {
    "obsidian": {
      "path": "C:/Users/SiaZh/OneDrive/SIA的obsidian系统",
      "description": "个人知识库：项目文档、任务笔记、设计文档、ADR"
    }
  }
}
```

## 工程级 AGENTS.md 的追加内容

工程内除了统一固定段，可追加**该项目特有绑定**（哪些是本项目必须记录的）：

```markdown
## 知识库绑定
- vault：`<vault 路径>`
- 本项目在知识库中的项目名：`<项目名>`
- 领域：`个人` / `工作` / ...
- 任务笔记目录：`<领域>/<项目名>/YYMMDD<任务>.md`
```
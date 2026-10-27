# 笔记仓库入口

向本 Obsidian 仓库新增或修改笔记前，**必须先完整读取同目录的 `规范.md`**，那是本仓库唯一规范事实源，包含目录结构、属性格式、wiki 内链规则、各笔记模板、以及操作规范。

规划文档（跨多天、多任务、需求会变）使用 skill `plan-doc`；vault 内笔记属性仍按 `规范.md`。优先用 `/plan-new`、`/plan-next`、`/plan-done`、`/plan-change`、`/plan-check`。

核心红线（详见 `规范.md`）：
- **禁止删除或修改任何文件，除非用户明确要求**
- 禁止修改 `.obsidian/`、`资源/`、`.claude/`、`.git/` 目录（用户明确要求时除外）
- 项目文件自身的 `项目` 字段用纯文本，其他文件用 `[[wikilink]]`
- 时间格式 `YYYY-MM-DDTHH:mm:ss` 必须带秒
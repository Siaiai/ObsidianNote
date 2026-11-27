# 合线回归：develop(R61) 独有改动是否都在合并树

- 任务：T6-7（只读，未改码、未 commit、未 checkout，全程只用三个固定提交对象）
- 日期：2026-11-27
- 仓库：`D:\Screen\HangerOperatePanel\Operation_Panel`
- 三个固定对象：
  - 合并 `02415c2`（`merge: 合入面板 develop(R61) 至全封闭线，版本升 C2A`）
  - C2 父 `188ab6c`
  - develop 父 `9fa6502`（R61）
- 方向约定：`git diff 02415c2 9fa6502` 中 **`+` 行 = develop 有、合并树没有**；`-` 行 = 合并树（C2 侧）独有。

---

## 0 结论

**14 个文件逐个核完：真丢失 1 处，其余全是「C2 侧是超集」或「有意替换」。**

| 判定 | 文件数 | 说明 |
|---|---|---|
| **真丢失** | **1** | `midware/rfidio.c:1177` 的 `if(tempIOOutIsHorizontal)`（已立 T6-6） |
| C2 有意替换（用户已定） | 3 | `LangMenu.c` 语言表整表、`MenuUI.h` 的 `CPVER/CPVERA`、`LangMenu.h` 的槽位 |
| 合并树是超集（C2 多出内容，未丢 develop） | 9 | 逐条见 §2 |
| 仅格式/注释/工程字段 | 1 | `MDK/HC32F460KETA.uvprojx` 编译器路径串 |

**需要用户定的：0 条。** 唯一有争议的 `ControllerLostTb` 槽位（develop 38 / 合并 37）已核清：控制器最大消息码是 **36**（`Panel.h:79 Msg_PowerOutMotorUnact = 36`），37 槽（0..36）刚好够，develop 多的那 1 槽是空的。

---

## 1 方法与口径

```bash
# 只碰这三个对象
git rev-list --parents -1 02415c2        # 02415c2 188ab6c 9fa6502
git diff --name-status 9fa6502 02415c2   # 14 个文件，全部 M，无 D（没有整文件被删）
git diff -w --numstat 02415c2 9fa6502 -- <file>   # + 行 = develop 独有
git diff -w -U6 02415c2 9fa6502 -- <file>         # 看上下文判性质
```

- **缩进先滤**：`-w` 后 `EXIT` 的 `+` 行总数从 4886 降到约 4830，主要集中在 `LangMenu.c`（4799 行是语言表整表差异）。
- **不看工作区**：嵌入式工程师正在同一仓库改 `rfidio.c`/`MenuUI.c`，本轮全部用 `git show <commit>:<file>`，工作区一个字节没读、没 checkout。
- **判定标准**：合并树里 C2 侧的内容若能覆盖 develop 的行为（同一逻辑的更全版本），记「超集」；若 develop 的改动在合并树里**完全没有对应物**，记「真丢失」。

---

## 2 逐文件清单（14 个）

`+` 列是 `-w` 后 develop 独有的行数。

| # | 文件 | `+` | 判定 | 依据（三版取值） |
|---|---|---|---|---|
| 1 | `MDK/HC32F460KETA.uvprojx` | 1 | 非功能 | develop `:13` `.\ARM_Compiler_5.06u7` ↔ 合并 `:13` `.\ARMCC`。同一编译器的安装路径字串，Keil 打开即重写 |
| 2 | `midware/CmdProtocol.c` | 0 | 无丢 | 合并比 develop 多 71 行（C2 协议扩展），develop 无独有内容 |
| 3 | `midware/CmdProtocol.h` | 0 | 无丢 | 合并多 3 行 |
| 4 | `midware/LangMenu.c` | 4799 | **C2 有意替换** | develop 是 27 语种整表；C2 是 16 槽（14 个空壳）。用户已定「语言就留中文、取 C2 侧整份、不并集」 |
| 5 | `midware/LangMenu.h` | 17 | 有效内容无丢 | 17 行是 develop 里**被注释掉的** `Horizontal_Storehouse_Menu_Param` 整段（死代码）。另有 3 处槽位差异：`MDebugTb` develop 8 → 合并 9、`MToastTb` 62 → 68、`ControllerLostTb` 38 → **37**（缩 1）。已核：控制器最大码 36，37 槽够 |
| 6 | `midware/MenuParam.c` | 3 | 合并是超集 | ① `func_table[34]` → 合并 `[38]`（多 4 个全封闭菜单项）；② 末项 `{33,…Menu_ReworkConfirm}//33` 只差末尾逗号；③ 出站偏移范围 develop `T1to20an99` → 合并 `T0to20an99`（C2 放宽允许 0） |
| 7 | `midware/MenuParam.h` | 1 | 合并是超集 | 合并多 6 个 Toast 枚举（62-67：`T0to20an99/T10to1000/T500to5000/RailRuning/T50to1000/T500to20000`）；`func_table[34]`→`[38]` 同步 |
| 8 | `midware/MenuUI.c` | 7 | 合并是超集（3 处全被 C2 取代） | ① `HangNoMax` develop 8 → 合并 9（调试菜单加「全封闭轨道」）；② `if(HangNo==7)/else if(HangNo==8) M_Nav_FullyEnclosedTrack` 被 C2 的分支取代；③ 出站偏移判定 develop `>= '1'` → 合并 `>= '0'`（配注释「出站偏移支持设置为0」） |
| 9 | `midware/MenuUI.h` | 2 | C2 有意 | `CPVER "R61"` / `CPVERA "V-CP061261010…"` → 合并 `"C2A"` / `"V-CP060260C2A 10:00:00 "`。用户已定版本升 C2A、构建段保 060 |
| 10 | `midware/key.c` | 2 | 合并是超集 | ① `M_SysParam‖M_IOinSet‖M_IOoutSet` 的广播白名单，合并多 3 个全封闭菜单；② 退出编辑模式的排除列表，合并多排 4 个全封闭功能（`M_Nav/Param/IOinSet/IOoutSet_FullyEnclosedTrack`） |
| 11 | `midware/rfidio.c` | 1 | **真丢失** | develop `:1177` `if(tempIOOutIsHorizontal)` 在合并树里没有，`Outsetmenu[tempIOOutId-8]->POutSetOCTb = 1;` 变成无保护。详见 §3 |
| 12 | `midware/uart/uart.c` | 0 | 无丢 | 合并多 34 行（C2 新增） |
| 13 | `midware/uart/uart.h` | 3 | 仅空行 | develop 多 3 个空行 |
| 14 | `source/MAIN.C` | 4 | 合并是超集 | ① `:207` 的 `funcIndex == M_IOinSet_FullyEnclosedTrack` 判定合并里有；② `tmpcmdres == 0x0006` 的 `//配置失败` 注释合并里有；余 2 行是上述删除块留下的空行 |

---

## 3 真丢失（唯一 1 处）

**`midware/rfidio.c`，develop `:1177`，合并后缺失。**

```c
// develop 9fa6502:midware/rfidio.c:1174-1180（Timer0B_CallBack 内，IconToastSign 1 秒到点）
    IconToastSign = 0;
    UpdateSign = 1;
    PIOoutSetOCTb[tempIOOutId] = 1;
    if(tempIOOutIsHorizontal)                          // ← develop 有，合并树没有
        Outsetmenu[tempIOOutId - 8]->POutSetOCTb = 1;
    //全封闭轨道（C2 侧新增，合并树保留）
    if(tempIOOutId < Menu_Fully_Enclosed_Track.OutNum){
        Menu_Fully_Enclosed_Track.OutItem[tempIOOutId].IoStatus = 0;
    }
```

三版取值：

| 版本 | `Outsetmenu[tempIOOutId - 8]->POutSetOCTb = 1;` |
|---|---|
| C2 父 `188ab6c` | 无保护（裸写） |
| develop 父 `9fa6502` | 有 `if(tempIOOutIsHorizontal)` |
| 合并 `02415c2` | **无保护**（取了 C2 侧） |

- 性质：合并把 develop 的保护整块丢了，`-w` 后仍只剩这 1 行差异，**不是格式问题**。
- 具体后果（已确认的因果链）：全封闭「测试输出」菜单触发时 `tempIOOutId = HangNo`（0/1/2），1 秒后 `tempIOOutId - 8` 为负下标，从 `Outsetmenu` 数组前面取指针再写 `POutSetOCTb` → 越界写。C2 出货版本就带这个隐患，不是本次合并引入，但合并也没修。
- 修复口径（用户已点头，立 T6-6）：必须两处一起——`rfidio.c` 恢复 `if`；`MenuUI.c` 全封闭「测试输出」分支补 `tempIOOutIsHorizontal = 0;`（该变量由 develop 带进来，全封闭路径从不赋值，只加 `if` 挡不住）。**这两处不在本报告范围内，由嵌入式工程师执行。**

---

## 4 抽查 5 条（三版取值）

| 抽查项 | C2 父 `188ab6c` | develop 父 `9fa6502` | 合并 `02415c2` | 判 |
|---|---|---|---|---|
| `rfidio.c` 保护 | 无 | `:1177` 有 `if` | 无 | **真丢失** |
| `MenuUI.c` 调试菜单项数 | 9 | 8 | 9 | C2 有意（加全封闭项） |
| `MenuParam.c` 出站偏移范围 | `T0to20an99` | `T1to20an99` | `T0to20an99` | C2 有意（允许设 0） |
| `LangMenu.h` `ControllerLostTb` | 37 | 38 | 37 | 有效无丢（控制器最大码 36） |
| `key.c` 广播白名单 | 含 6 个全封闭菜单 | 只 3 个基础菜单 | 含 6 个全封闭菜单 | 合并是超集 |

---

## 5 未覆盖

1. **只核了「行级」丢失**，没做「语义级」核对——例如 develop 改了某常量值而 C2 有同名不同值的常量，行级 diff 会显示为两侧都改过，需要人读。本轮靠 `-w` 后的 `+` 行清单全覆盖（共约 40 行，已逐行判），`-` 行（C2 独有 8000+ 行）未逐行核，因为方向是「C2 是否丢了 develop 的东西」，C2 自己的新增不在本任务范围。
2. **`LangMenu.c` 的 4799 行只做了定性判断**（整表替换），没逐语种核 C2 的 14 个空壳槽位有没有错位。T6-2 时已核过索引不删、只留中文可选。
3. **未编译**：本次不涉及源码改动，未跑 Keil；T6-6 改完后的编译由执行方报。
4. **未上板**：越界写的实际表现（跑飞 / 静默改内存）无法静态证伪。
5. `MenuParam.h` 的 6 个新 Toast 枚举（62-67）与 `MToastTb[68]` 的对应关系未逐条核——这是 C2 自己的新增，不属于「develop 独有丢失」。

---

## 6 复现命令

```bash
cd D:/Screen/HangerOperatePanel/Operation_Panel

# 三个对象与文件面
git rev-list --parents -1 02415c2
git diff --name-status 9fa6502 02415c2          # 14 个 M，无 D
git diff -w --numstat 02415c2 9fa6502          # + 行 = develop 独有

# 真丢失那一处
git show 9fa6502:midware/rfidio.c | sed -n '1170,1185p'
git show 02415c2:midware/rfidio.c | sed -n '1170,1182p'
git show 188ab6c:midware/rfidio.c | sed -n '1170,1182p'

# 槽位缩水的验证依据
git show 9fa6502:midware/LangMenu.h | grep ControllerLostTb
git show 02415c2:midware/LangMenu.h | grep ControllerLostTb
cd D:/S3/Project/S3_Controller
git grep -n "Msg_PowerOutMotorUnact" 全封闭轨道/v3/develop -- APP/Panel.h    # = 36，最大码

# 逐文件看 + 行
git diff -w -U6 02415c2 9fa6502 -- midware/key.c
git diff -w -U6 02415c2 9fa6502 -- midware/MenuParam.c
git diff -w -U6 02415c2 9fa6502 -- source/MAIN.C
```

---

*本文只做回归定位，不含修法。修法归架构师，实现归对应工程师。*

---
area: "[[工作]]"
status: DOING
createTime: 2026-07-28 23:41:39
deadline: 2026-07-31T23:41
doneTime:
tags:
  - project
  - code
type: none
---

## 待办列表
- [ ] 编码
- [ ] 测试
- [ ] 合并

## 方案

```mermaid
flowchart TD
    subgraph host["块1·上位机(离线产资源)"]
        Src[源字体] -->|hb-subset| Sub[子集字体·带轮廓]
        Sub -->|剥glyf·CFF| SF[shape字体·无轮廓]
        Sub -->|HB·FreeType栅格化| Atlas[图集<br/>w·h·bx·by·bitmap]
        SF --> Pkg[(资源包<br/>shape字体·图集·清单)]
        Atlas --> Pkg
    end

    subgraph dev["块2·下位机(运行时消费)"]
        Pkg -.->|"shape字体"| Font[hb_face·hb_font]
        In["UTF-8文本"] --> BiDi["BiDi分段<br/>(仅RTL触发)"]
        BiDi --> Shape["hb_shape<br/>GSUB·GPOS"]
        Font --> Shape
        Shape --> Out["HarfBuzz输出<br/>gid·cluster·advance·offset"]
        Out -->|"advance·cluster"| Layout["行排版<br/>断行·对齐·基线"]
        Pkg -.->|"图集"| AL["图集<br/>w·h·bx·by·bitmap"]
        Layout -->|"gid"| AL
        Layout -->|"pen·Shift"| Merge["合成坐标<br/>pen+Shift+Bearing"]
        AL -->|"bearing·bitmap"| Merge
        Merge --> Blit["blit->shadow buffer"]
        Blit --> Screen[刷屏]
    end

    classDef hb fill:#e3f2fd,stroke:#1565c0,color:#0d47a1
    classDef at fill:#e8f5e9,stroke:#2e7d32,color:#1b5e20
    classDef res fill:#fff3e0,stroke:#e65100,color:#bf360c
    classDef rnd fill:#fafafa,stroke:#757575,color:#212121

    class In,BiDi,Font,Shape,Out,Layout hb
    class AL at
    class Src,Sub,SF,Atlas,Pkg res
    class Merge,Blit,Screen rnd
```

## 项目结构

harfembed/
├── docs/                               # 文档
├── res/
│   ├── fonts/                          # 源字体，CLI 输入
│   │   ├── xxx.ttf
│   │   └── xxx.otf
│   └── fontlets/                          # 生成产物
│       ├── fontlets_registry.h        # 生成的 fontlet 索引
│       ├── common.fontlet
│       ├── latn.fontlet
│       ├── hani.fontlet
│       └── hans.fontlet
├── src/
│   ├── third_party/                   # harfbuzz / freetype
│   ├── fonlet_generator_cli/       # 生成fontlet
│   │   └── CMakeLists.txt
│   └── harfembed/                   # MCU 库
│       ├── CMakeLists.txt
│       └── inc/                          # 公共 API 头（含 fontlet_format.h）
├── examples/
│   └── CMakeLists.txt
├── tests/
│   └── CMakeLists.txt
├── .gitignore
├── CMakeLists.txt
├── LICENSE
└── README.md


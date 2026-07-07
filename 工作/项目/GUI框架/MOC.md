---
area: "[[工作]]"
status: DOING
createTime: 2026-07-07
deadline:
doneTime:
tags:
  - mainproject
  - project
type: 项目索引
---

## 待办列表
- [x] 初始化项目笔记结构(MOC + 架构总览)
- [ ] 写「三阶段主循环」模块笔记
- [ ] 写「页面与导航栈」模块笔记
- [ ] 写「组件机制与 vtable」模块笔记
- [ ] 写「事件路由链」模块笔记
- [ ] 写「画布与裁剪」模块笔记
- [ ] 写「列表组件」模块笔记
- [ ] 写「按钮组件」模块笔记
- [ ] 写「弹窗系统」模块笔记

## 项目概况

一个面向嵌入式 RTOS 面板的小型、单线程、事件驱动 GUI 框架,C11 实现。框架本身硬件无关,通过 4 函数 HAL(`draw_pixel` / `clear` / `refresh` / `get_time`)对接世界。库内无动态分配——所有页面、组件、列表项、事件表均由用户静态定义,运行时链接。

代码仓库:`D:\Screen\Projects\Panel_RTOS\02_Middleware\GUI`(Win32 LCD 模拟器作为开发宿主目标)。

## 架构骨架

三阶段主循环 `UI_Loop`(`src/ui.c`):`UI_Events()` → `UI_Proc()` → `UI_Draw()`,周而复始。单全局 `g_ui` 持有页面栈、当前页面、默认事件表、当前裁剪矩形、弹窗栈、刷新时序。

核心抽象四件套:页面(上下文+调度器)、组件(vtable 分派)、事件路由(4 层)、画布(层级裁剪)。详见 [[架构总览]]。

## 当前进度

框架主体已实现,Win32 LCD 模拟器跑通。已有组件:text、list、button、popup 四类 vtable。弹窗系统已统一为 tabbar 模式(优先级栈 + 点指示器)。

README.md 里记录的待办设计意图(尚未实现):NAV/EDIT/MODAL 三层编辑模式、原地列表编辑、模态编辑器。

## 下一步

按架构总览铺开各模块的深度笔记(主循环 / 页面 / 组件 / 事件路由 / 画布 / 列表 / 按钮 / 弹窗)。每篇模块笔记对应代码里一个核心文件,记录实现要点、设计权衡、扩展位置。

## 关键笔记

- [[架构总览]] — GUI 框架整体架构导览
- (后续模块笔记将陆续挂在这里)

## 外部资源

- 代码仓库:`D:\Screen\Projects\Panel_RTOS\02_Middleware\GUI`
- 代码架构说明:`D:\Screen\Projects\Panel_RTOS\02_Middleware\GUI\CLAUDE.md`(代码仓库内,不进 vault)
- README.md 设计备忘:代码仓库根目录,记录 NAV/EDIT/MODAL 等未实现的设计意图

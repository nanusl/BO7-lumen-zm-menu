# BO7 ZM Menu

一个面向《使命召唤：黑色行动 7》（Call of Duty: Black Ops 7）僵尸模式（ZM）的
游戏内脚本菜单。用 GSC 写成，编译成 `.gscc` 后投放到注入框架的脚本目录，
进入对局后按组合键呼出，用来快速调试、测试和娱乐。

脚本本身不含任何注释，所有设计说明、编译流程和注意事项都集中在本文件里。

---

## 适用范围

**本脚本只针对 Lumen 离线补丁，不保证在任何其他环境下可用。**

| 项 | 值 |
|---|---|
| 补丁名称 | **Lumen**（COD 版离线补丁） |
| 注入文件 | `XInput9_1_0.dll` |
| 数据目录 | `%appdata%\Lumen_COD\`（本地副本：`offline-bo7/Lumen_COD/`） |
| 工作方式 | 游戏启动时被加载，提供 GSC 脚本注入 |
| 脚本目录 | `<游戏目录>\saturn\Assets\Scripts\` |
| 启用前提 | `saturn/settings.json` 里 `"disableGsc": false` |
| 脚本清单 | `saturn/Assets/Scripts/script_manager.json` 的 `disabledScripts` 里不能包含目标脚本 |

不适配的情况：

- 正版在线对局、官方服务器、任何公开匹配
- 其他注入框架或脚本加载器。`.gscc` 的头部结构、字符串表回填规则、
  脚本目录约定都是按 Lumen 的加载器实现的，换一个加载器需要重新适配
- 任何需要绕过反作弊的场景

`fix_gscc.py` 里的占位符回填规则（magic `0A0D4353471A`、字符串表偏移 `0x54`、
占位符 `0x12345678`）同样是按 Lumen 能接受的 `.gscc` 形态写的。换成别的加载器时，
这套规则不一定成立，投放前必须重新验证。

---

## 功能

菜单共 6 页。所有条目在游戏里以 `^6` 品红色显示，序号用白色，操作结果用
`^5` 功能名 + `^2` 成功 / `^1` 失败提示。

### 主页 MAIN

| 条目 | 类型 | 说明 |
|---|---|---|
| 玩家 | 子页 | 进入玩家功能页 |
| 娱乐 | 子页 | 进入娱乐功能页 |
| 奇迹武器 | 子页 | 进入奇迹武器页 |
| 老特西 | 执行 | 在玩家位置召唤 Wonder Vehicle（Pluto / Tessie） |
| 关闭菜单 | 关闭 | 收起菜单 |

### 玩家 PLAYER

| 条目 | 类型 | 说明 |
|---|---|---|
| 无敌 | 开关 | 玩家无敌 |
| 终极火力 | 开关 | 组合开关，一次打开多个增益 |
| 终极稀有度 | 执行 | 把当前主武器品阶拉到 5 |
| 4级超改 | 执行 | 重建当前武器并打到 Pack-a-Punch 4 级 |
| 忽略 | 开关 | 让 AI 忽略玩家 |
| 黄金甲 | 开关 | 开启黄金护甲 |
| 满精华&废料 | 执行 | 精华、废料补满 |
| 全特长 | 执行 | 发放全部特长 |
| 满自救 | 执行 | 补满自我复活 |
| 随机泡泡糖 | 执行 | 把随机泡泡糖写入空闲槽 |
| 存点 | 执行 | 记录当前位置 |
| 读点 | 执行 | 传送回记录点 |

### 娱乐 FUN

| 条目 | 类型 | 说明 |
|---|---|---|
| 跳回合 | 子页 | 进入回合选择页 |
| 一键清场 | 执行 | 清除场上所有 AI |
| 停刷怪 | 开关 | 暂停刷怪 |
| 掉落 | 子页 | 进入掉落物页 |
| 友方召唤 | 执行 | 按当前地图召唤该图存在的 AI 作为友方 |

### 回合 ROUND

第 1 / 25 / 50 / 100 / 500 / 998 回合，共 6 档。

### 掉落 POWERUP

双倍积分、弹药全满、护甲全满、火力全开、随机特长、清仓甩卖、核弹、
额外分数、维萨里昂的祝福、卡瑟莉丝的祝福、德拉瓦卡之祝福，共 11 种。

### 奇迹武器 WONDER

亡灵拳套、猫灵法师、约顿之星、霰弹铁铳、LGM-1、典狱长之疫、
射线枪、射线枪 2 型，共 8 把。

---

## 目录结构

```
bo7-zm-menu/
├── LICENSE                      Apache License 2.0
├── README.md                    本文件
├── .gitignore
├── build.py                     一键编译 + 修补 + 投放
├── fix_gscc.py                  .gscc 字符串占位符回填与校验
└── scripts/
    └── bo7_zm_menu.gsc         菜单源码（无注释）
```

---

## 环境要求

- Windows（投放路径和 ACTS 编译器都是 Windows 环境）
- Python 3.8+
- ACTS 的 `gscc` 编译器，命令形如：

  ```
  acts gscc -g bo7 -p pc --name <name> -o <output> <source>
  ```

  `acts` 需要在 `PATH` 里，或者用 `--cli` 指定完整路径。

- **Lumen** 离线补丁（注入文件为 `XInput9_1_0.dll`），脚本目录约定为：

  ```
  D:\cod25\saturn\Assets\Scripts\
  ```

  Lumen 在游戏启动时加载，负责把 `.gscc` 注入到对应的脚本位置。
  换用别的加载器不保证可用，见上面的「适用范围」。

---

## 编译与投放

### 一键构建

```bash
python build.py
```

默认行为：

1. 用 `acts` 编译 `scripts/bo7_zm_menu.gsc`
2. 回填 `.gscc` 里的字符串占位符
3. 校验文件头哈希、命名空间、残留占位符
4. 复制到 `D:\cod25\saturn\Assets\Scripts\script_6f294f32b60c71f4.gscc`

常用参数：

```bash
python build.py --cli "C:\path\to\acts.exe"
python build.py --out "D:\cod25\saturn\Assets\Scripts"
python build.py --no-copy          # 只编译，不复制
```

编译产物落在 `build/` 目录，可以直接检查。

### 手动构建

```bash
acts gscc -g bo7 -p pc --name script_6f294f32b60c71f4 -o build/script_6f294f32b60c71f4 scripts/bo7_zm_menu.gsc
python fix_gscc.py --ns namespace_ced633acc59ac526 build/script_6f294f32b60c71f4.gscc
```

然后把生成的 `.gscc` 复制到注入目录。

### 投放目标

| 项 | 值 |
|---|---|
| 目标脚本 | `scripts/mp/playercards.gsc` |
| 资产哈希 | `6F294F32B60C71F4` |
| 文件名 | `script_6f294f32b60c71f4.gscc` |
| 命名空间 | `namespace_ced633acc59ac526` |

同一时间只应投放一个占用该哈希的产物。若之前投放过别的测试脚本，
先把它移走，避免互相覆盖。

---

## 菜单操作

| 操作 | 按键 |
|---|---|
| 打开菜单 | 瞄准（ADS）+ 近战，同时按住 |
| 上移 | 瞄准（ADS） |
| 下移 | 开火 |
| 确认 | 交互 / 使用 |
| 返回 | 近战 |

菜单关闭时，每 20 秒会在屏幕上提示一次上述按键。

---

## 技术说明

### 为什么需要 fix_gscc.py

ACTS 编译器产出的是「未链接形态」：每个字符串引用槽里放的是占位符
`0x12345678`，真实偏移记录在字符串表里。游戏成品里这些槽是编译期写死的
实值，所以投放前必须按字符串表把占位符回填成实际偏移，否则运行时会读到
非法地址。

`fix_gscc.py` 做的就是这个回填，附带三项校验：

- 文件头 `+8` 的哈希要和文件名里的哈希一致
- 每个导出项的 `name_space` 必须非 0 且等于声明的命名空间
- 文件里不能残留任何 `0x12345678`

### .gscc 结构速查

| 偏移 | 含义 |
|---|---|
| `0x00` | magic，`0x0A0D4353471A` |
| `0x08` | 资产哈希 |
| `0x18` | 导出项数量（`H`） |
| `0x22` | 字符串项数量（`H`） |
| `0x40` | 导出表偏移（`I`） |
| `0x54` | 字符串表偏移（`I`） |

BO7 的导出项是 40 字节：`name(8) / namespace(8) / fns(8) / checksum(4) /
address(4) / pc(1) / flags(1) / pad(6)`。

### 依赖的脚本

源码 `#using` 了以下模块，全部是游戏自带脚本，不需要额外投放：

| 模块 | 用途 |
|---|---|
| `scripts\common\utility` | 共享函数调用、flag、结构体工具 |
| `scripts\common\weapon` | 武器构建与修复 |
| `scripts\common\callbacks` | 玩家事件回调、打包完成广播 |
| `scripts\common\status_effects\effect_charm` | AI 倒戈 |
| `scripts\mp\zm\systems\zm_armor` | 护甲与黄金甲 |
| `scripts\mp\zm\systems\agent_manager` | AI 生成 |

---

## 已知限制

- **奇迹武器**：资产名需要先经 `weapon::getweaponrootname` 转换再构建，
  直接给字符串建出来是空武器。个别名字若在当前地图不存在，会静默失败。
- **品阶 5**：只对主武器槽生效。出生自带的手枪在副武器槽，取不到数据，
  需要先拿到一把主武器。
- **Pack-a-Punch 4 级**：`level.pap_camos` 实际只有 3 项，4 级没有对应迷彩，
  外观可能看不出变化；数值和附件仍然生效。
- **老特西配件**：配件装配逻辑依赖 `zm_firefly_pluto` 注册的共享函数。
  非 firefly 地图上可能只有车体没有配件，这是图数据限制。
- **友方召唤**：按 `level.mapname` 分派，每张图使用该图脚本里真实生成过的
  aitype。召唤后依靠 `_blackboard` 的主人标记和仇恨半径让它主动作战。
- **字体**：菜单文字全部是中文，原生字体不含中文字形，部分环境可能显示为
  方块或空白。

---

## 免责声明

本项目仅供**单人 / 离线 / 私人环境**下的学习、调试与娱乐使用。

- 本项目只适配 **Lumen** 离线补丁，且仅在 Lumen 下测试过。
  在其他注入环境里出现的问题不在支持范围内。
- 请勿在官方服务器、公开匹配或其他玩家的对局中使用。
- 使用第三方脚本修改游戏可能违反游戏的服务条款，由此产生的封号、
  数据损失或其他后果由使用者自行承担。
- 作者不对任何直接或间接损失负责。

---

## 许可

本项目采用 [Apache License 2.0](LICENSE) 授权。

```
Copyright 2026 BO7 ZM Menu contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

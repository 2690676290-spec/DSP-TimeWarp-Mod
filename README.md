# 戴森球计划 加速 Mod（DSP SpeedUp）

一个基于 **BepInEx 5** 的《戴森球计划》游戏速度调节 Mod。

它不是修改某个建筑或某种物流的速度，而是直接调节 Unity 的 `Time.timeScale`：
游戏里所有按固定时间步推进的逻辑（工厂生产、传送带、采集、科研、机甲移动、太阳帆/火箭飞行等）都会一起加速；
主菜单、读盘界面和 ESC 暂停界面仍保持 1x，不会出现菜单动画失控。

- 游戏版本：Dyson Sphere Program 0.10.35.29151（Unity 2022.3.62f3）
- 框架：BepInEx 5.4.23.6 x64（已随安装包附带）
- 平台：Windows x64 / Steam

---

## 功能

- **1x – 20x** 可调速度（默认 2x，上限可在配置中改到 100x）。
- **F9** 加速一档，**F8** 减速一档，**F10** 立即回到 1x。
- 默认档位：`1, 2, 3, 5, 10`；超过 10x 后按 2 倍递增，直到 `MaxSpeed`。
- 右上角 HUD 实时显示当前倍速；**Alt + F8** 显示/隐藏 HUD。
- 每次载入存档自动恢复为 `DefaultSpeed`（默认 2x），不会把上一个存档的倍速带过来。
- 暂停（ESC）时自动回到 1x，恢复游戏后重新应用倍速。
- 所有快捷键、默认倍速、档位、HUD 开关都可以在配置文件中修改。

## 安装

### 方式 A：手动解压（推荐，最直观）

1. **先关闭游戏**。
2. 在 Steam 库中右键《Dyson Sphere Program》→「管理」→「浏览本地文件」，打开游戏根目录
   （应能看到 `DSPGAME.exe`）。
3. 把安装包里的所有内容解压/复制到该目录，最终结构应为：

   ```text
   Dyson Sphere Program\
   ├─ DSPGAME.exe
   ├─ winhttp.dll
   ├─ doorstop_config.ini
   ├─ .doorstop_version
   ├─ changelog.txt
   └─ BepInEx\
      ├─ core\...
      └─ plugins\DSPSpeedUp\DSPSpeedUp.dll
   ```

4. 启动游戏。首次启动会自动生成 `BepInEx\config\dsp.speedup.cfg`。
5. 进入存档后，右上角出现 `Game Speed x2` 即安装成功。

### 方式 B：脚本安装

把安装包解压到任意位置，在解压目录中打开 PowerShell：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

脚本会自动从 Steam 注册表 / `libraryfolders.vdf` 中查找游戏目录；找不到时手动指定：

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -GameDir "F:\SteamLibrary\steamapps\common\Dyson Sphere Program"
```

如果检测到已经安装过 BepInEx，脚本只复制本 Mod，不会覆盖你现有的 BepInEx 框架和其他 Mod。

## 使用

| 操作 | 默认按键 | 说明 |
| --- | --- | --- |
| 加速 | `F9` | 按预设档位升一档 |
| 减速 | `F8` | 按预设档位降一档 |
| 恢复 1x | `F10` | 立即回到正常速度 |
| 显示/隐藏 HUD | `Alt + F8` | 也可在配置里关闭 |

> F8–F10 是原版游戏没有占用的功能键（原版 F11 隐藏 UI、F12 显示 FPS）。
> 如果你的其他 Mod 占用了这些键，直接在配置里改成别的即可。

### 配置文件

路径：`BepInEx\config\dsp.speedup.cfg`（首次运行后生成）

```ini
[General]

## Master switch for the speed multiplier.
# Setting type: Boolean
# Default value: true
Enabled = true

## Speed multiplier applied when a game starts.
# Setting type: Single
# Default value: 2
# Acceptable value range: From 1 to 100
DefaultSpeed = 2

## Speed steps used by the hotkeys, separated by commas.
# Setting type: String
# Default value: 1,2,3,5,10
Presets = 1,2,3,5,10

## Upper limit for the speed multiplier.
# Setting type: Single
# Default value: 20
# Acceptable value range: From 1 to 100
MaxSpeed = 20

[UI]

## Show the current speed multiplier in the top-right corner.
# Setting type: Boolean
# Default value: true
ShowHud = true

[Hotkeys]

## Increase the game speed.
# Setting type: KeyboardShortcut
# Default value: F9
SpeedUp = F9

## Decrease the game speed.
# Setting type: KeyboardShortcut
# Default value: F8
SpeedDown = F8

## Reset the game speed to 1x.
# Setting type: KeyboardShortcut
# Default value: F10
Reset = F10

## Show or hide the speed indicator.
# Setting type: KeyboardShortcut
# Default value: LeftAlt + F8
ToggleHud = LeftAlt + F8
```

- 修改配置后需要重启游戏生效。
- `DefaultSpeed` 超过 `MaxSpeed` 时会被自动夹到上限。
- 键盘快捷键写法遵循 BepInEx：`F9`、`LeftAlt + F8`、`LeftControl + F9` 等。

## 原理（为什么不需要 Harmony 补丁）

游戏的主循环在 `GameMain.FixedUpdate()` 中按固定时间步运行：

- 正常情况下每个 Unity FixedUpdate 执行 1 个逻辑帧，游戏时间 = tick 数 / 60；
- `Time.fixedDeltaTime` 由 `FPSController.Update()` 设置为 `min(1/60, Time.deltaTime * fixRatio) / SimulateSpeed`；
- `Time.timeScale` 会同时放大 `Time.deltaTime` 和 Unity 的固定步长调度。

因此只要把 `Time.timeScale` 设为 N，单位真实时间内就会执行约 N 倍的逻辑帧，整个工厂和玩家机甲都会以 N 倍速运转。
本 Mod 只在 `GameMain.isRunning == true` 且未暂停时接管 `Time.timeScale`，菜单、读盘和暂停界面不动它。

这样做的好处是：

- 不依赖 `GameMain` 内部私有字段，游戏小版本更新后不易失效；
- 支持小数倍速（例如 1.5x、2.5x）；
- 不需要 Harmony，兼容大多数其他 BepInEx Mod。

代价是游戏内的 UI 动画、镜头平滑等也会按倍速播放；ESC 暂停菜单已经单独排除，保持 1x。
高倍速下能否真正达到 N 倍取决于 CPU：后期工厂很大时，Unity 会因帧时间不足而自动放慢，这是正常现象。

## 兼容性

- 适用于 Steam 版《戴森球计划》0.10.35.29151（Unity 2022.3 Mono x64）。
- 需要 BepInEx 5.4.23.6 x64；安装包已附带，不需要单独下载。
- 可与大多数 BepInEx 5 Mod 共存；如果另一个 Mod 也在改 `Time.timeScale`（例如其他加速 Mod），会互相覆盖，请只保留一个。
- 游戏本体大更新后，BepInEx 可能需要同步更新；如果进游戏没有 HUD，先看 `BepInEx\LogOutput.log`。
- 本 Mod 不改变存档格式，卸载后存档仍可正常使用。

## 卸载

1. 关闭游戏。
2. 删除 `BepInEx\plugins\DSPSpeedUp\` 文件夹。
3. 删除 `BepInEx\config\dsp.speedup.cfg`（可选）。
4. 如果不想保留 BepInEx 框架，再删除 `BepInEx\`、`winhttp.dll`、`doorstop_config.ini`、`.doorstop_version`、`changelog.txt`。
   **注意：** 如果还有其他 BepInEx Mod，不要删除整个 `BepInEx\` 文件夹。

## 故障排查

| 现象 | 处理 |
| --- | --- |
| 进游戏没有右上角 HUD | 确认游戏根目录有 `winhttp.dll`、`doorstop_config.ini`、`BepInEx\core\BepInEx.Preloader.dll`；查看 `BepInEx\LogOutput.log` 是否有 `DSP SpeedUp 1.0.0 loaded` |
| 日志里没有 BepInEx 启动信息 | 杀毒软件可能拦截了 `winhttp.dll`，把游戏目录加入白名单；确认 Steam 启动的是 `DSPGAME.exe` 而不是其他版本 |
| 有 HUD 但速度不变 | 确认已进入存档（主菜单不加速）；看配置 `Enabled = true`；按 F10 再按 F9 试试 |
| 按键没反应 | 可能与其他 Mod/软件冲突，改 `[Hotkeys]` 里的键位并重启游戏 |
| 游戏卡顿/速度上不去 | 高倍速受 CPU 限制，降低 `MaxSpeed` 或改用 2–5x |
| 游戏更新后失效 | 更新 BepInEx 到支持新版本游戏的版本；本 Mod 本身通常不需要改 |

日志位置：`游戏根目录\BepInEx\LogOutput.log`。

## 从源码构建

需要 .NET SDK 8（或更高）以及游戏本体的 `Managed` 目录。

```powershell
dotnet build src\DSPSpeedUp\DSPSpeedUp.csproj -c Release `
  -p:DspManaged="F:\SteamLibrary\steamapps\common\Dyson Sphere Program\DSPGAME_Data\Managed"
```

- 目标框架 `net472`，通过 `Microsoft.NETFramework.ReferenceAssemblies` 提供引用程序集。
- 引用的 BepInEx 程序集位于 `_ref\bepinex\BepInEx\core\`。
- 输出：`src\DSPSpeedUp\bin\Release\DSPSpeedUp.dll`。

### 目录结构

```text
src\DSPSpeedUp\Plugin.cs        Mod 源码
src\DSPSpeedUp\DSPSpeedUp.csproj
dist\DSP-SpeedUp-1.0.0\         可直接复制到游戏根目录的安装包
dist\DSP-SpeedUp-1.0.0.zip      上述安装包的压缩版
install.ps1                     安装脚本（位于安装包内）
_tools\DumpAsm\                 分析 Assembly-CSharp 的小工具（开发用）
```

## License

MIT。BepInEx 及其组件遵循其各自的许可证（LGPL-2.1）。
